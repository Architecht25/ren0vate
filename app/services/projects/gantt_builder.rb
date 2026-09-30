module Projects
  # GanttBuilder
  #
  # Construit les données du planning Gantt d'un chantier. Priorité au devis
  # contractuel réel (DevisDonnee entrepreneur retenu + bordereau châssis),
  # repli automatique sur l'estimateur interne (Quote/QuoteItem + catalogue
  # WorkType) tant qu'aucun devis entrepreneur n'a été désigné comme retenu.
  class GanttBuilder
    # Durée indicative en jours par catégorie de poste de devis
    # (Documents::DevisDonnee::TYPES_TRAVAUX_VALIDES), dérivée des duration_avg
    # du catalogue WorkType (identiques entre régions/pays — seuls les prix
    # varient). Valeurs indicatives, ajustables empiriquement.
    CATEGORY_DURATION_DAYS = {
      'isolation_toit'              => 5.0,   # isolation_toiture
      'isolation_facade'            => 7.5,   # isolation_murs_ext
      'isolation_sol'               => 3.5,   # isolation_plancher
      'isolation_murs'              => 5.5,   # isolation_murs_int
      'chassis_vitrage'             => 3.5,   # chassis_pvc
      'chauffage'                   => 1.5,   # chaudiere_condensation
      'sanitaire'                   => 5.5,   # plomberie_renovation
      'electricite'                 => 5.0,   # electricite_conformite
      'gaz'                         => 1.5,   # approximation chaudiere_condensation
      'maconnerie'                  => 6.5,   # murs_porteurs
      'carrelage_revetement'        => 5.0,   # carrelage_sol
      'plafonnage_peinture'         => 4.5,   # peinture_int
      'toiture'                     => 15.0,  # toiture_remplacement
      'pompe_chaleur'               => 4.0,   # pompe_chaleur_air_eau
      'ventilation'                 => 1.5,   # ventilation_c_plus
      'chauffe_eau_thermodynamique' => 1.5,   # match exact
      'photovoltaique'              => 3.0,   # panneaux_solaires
      'eclairage'                   => 5.0,   # approximation electricite_conformite
      'audit_energetique'           => 1.0,   # visite technique, pas de chantier
      'renovation_generale'         => 10.0,  # fallback, scope large
      'autre'                       => 4.0    # fallback générique
    }.freeze

    OVERLAP_OFFSET_DAYS = 2 # même chevauchement arbitraire que l'ancien estimateur

    def initialize(project)
      @project = project
    end

    def source
      @source ||= devis_entrepreneur_retenu.present? ? :devis : :estimation
    end

    def bars
      @bars ||= source == :devis ? bars_from_devis : bars_from_quote
    end

    def milestones
      @milestones ||= begin
        list = []
        list << { date: @project.date_début, label: 'Début chantier', color: 'success' } if @project.date_début
        factures.each do |f|
          next unless f.date_facture
          list << { date: f.date_facture, label: "Facture #{f.type_facture&.humanize}", color: 'warning' }
        end
        [devis_architecte_retenu, devis_entrepreneur_retenu].compact.each do |devis|
          next unless devis.date_devis
          list << { date: devis.date_devis, label: "Devis #{devis.categorie_emetteur} signé", color: 'info' }
        end
        list << { date: @project.date_fin, label: 'Fin prévue', color: 'danger' } if @project.date_fin
        list.sort_by { |m| m[:date] }
      end
    end

    def latest_quote
      @latest_quote ||= quotes.first
    end

    private

    def start_date
      @project.date_début || Date.today
    end

    def factures
      @factures ||= @project.factures.order(:date_facture)
    end

    def quotes
      @quotes ||= @project.property&.quotes&.includes(:quote_items)&.order(created_at: :desc) || []
    end

    def devis_entrepreneur_retenu
      @devis_entrepreneur_retenu ||= DevisDonnee.retenu_ou_unique(@project, 'entrepreneur')
    end

    def devis_architecte_retenu
      @devis_architecte_retenu ||= DevisDonnee.retenu_ou_unique(@project, 'architecte')
    end

    def bordereau_chassis
      @bordereau_chassis ||= @project.bordereau_chassis_donnees.order(created_at: :desc).first
    end

    # ── Construction depuis le devis contractuel réel ────────────────────────
    def bars_from_devis
      cursor = start_date
      list = []

      devis_entrepreneur_retenu.postes.each do |poste|
        duration = CATEGORY_DURATION_DAYS[poste[:categorie].to_s] || CATEGORY_DURATION_DAYS['autre']
        end_date = cursor + duration.ceil.days
        montant = poste[:montant_htva].to_f

        list << {
          key:       poste[:categorie],
          name:      poste[:libelle].presence || DevisDonnee.categorie_libelle(poste[:categorie]),
          icon:      'tools',
          category:  poste[:categorie].to_s,
          source:    'devis',
          start:     cursor,
          end:       end_date,
          total_min: montant,
          total_max: montant,
          total_avg: montant
        }
        cursor += OVERLAP_OFFSET_DAYS.days
      end

      if bordereau_chassis.present? && bordereau_chassis.montant_htva.present?
        duration = CATEGORY_DURATION_DAYS['chassis_vitrage']
        montant  = bordereau_chassis.montant_htva.to_f
        list << {
          key:       'chassis_vitrage',
          name:      DevisDonnee.categorie_libelle('chassis_vitrage'),
          icon:      'window',
          category:  'chassis_vitrage',
          source:    'bordereau_chassis',
          start:     cursor,
          end:       cursor + duration.ceil.days,
          total_min: montant,
          total_max: montant,
          total_avg: montant
        }
      end

      list
    end

    # ── Repli estimateur (comportement historique, inchangé) ─────────────────
    def bars_from_quote
      quote = latest_quote
      return [] unless quote

      cursor = start_date
      quote.quote_items.map do |item|
        wt = WorkType.find(item.work_type_key, region: quote.property.region)
        next unless wt

        duration = item.unit_price_min.present? ? (wt.duration_min + wt.duration_max) / 2.0 : wt.duration_min
        end_date = cursor + duration.ceil.days
        bar = {
          key: item.work_type_key, name: wt.name, icon: wt.icon, category: wt.category,
          start: cursor, end: end_date,
          total_min: item.total_min, total_max: item.total_max,
          total_avg: item.total_avg || ((item.total_min.to_f + item.total_max.to_f) / 2).round(2)
        }
        cursor += OVERLAP_OFFSET_DAYS.days
        bar
      end.compact
    end
  end
end
