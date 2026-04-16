class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [:show, :edit, :update, :destroy, :gantt, :edit_budget, :update_budget, :edit_professionals, :update_professionals, :fin_chantier, :scan_peb_apres, :scan_audit_energ, :update_fin_chantier, :reception_chantier, :scan_attestation_conformite, :garanties, :check_contrat, :carnet_entretien, :roi_calculator, :analyze_photos, :vision_status, :score_sante, :validate_phase, :compare_devis]

  def index
    # Récupérer les projets, filtrer par property_id si fourni
    base_projects = current_user.projects.includes(:property)

    if params[:property_id].present?
      @property = current_user.properties.find(params[:property_id])
      @projects = base_projects.where(property: @property).order(created_at: :desc)
    else
      # Récupérer et trier les projets par région de la propriété (Flandre → Bruxelles → Wallonie)
      @projects = base_projects.order(created_at: :desc).sort_by do |project|
        case project.property&.region&.downcase
        when 'flandre' then 1
        when 'bruxelles' then 2
        when 'wallonie' then 3
        else 4 # Projets sans propriété ou sans région en dernier
        end
      end
    end
  end

  # Vue pour les professionals invités (entrepreneurs, architectes)
  def member_projects
    @memberships = current_user.project_members.active.pros.includes(project: :property)
  end

  def show
    @current_tab = params[:tab].presence_in(%w[preparation suivi reception]) || 'preparation'
    @documents = @project.documents.order(created_at: :desc) if @project.documents.respond_to?(:order)
    photo_types = %w[photo_avant photo_pendant photo_apres photo_chassis]
    @photos = @project.documents.where(type_document: photo_types).order(created_at: :desc)
    @photos_by_type = @photos.group_by(&:type_document)

    # Devis scannés par OCR
    @devis_scanne_architecte  = @project.devis_ocr_architecte
    @devis_scanne_entrepreneur = @project.devis_ocr_entrepreneur
    @devis_scanne_autres       = @project.devis_donnees.par_categorie('autre').avec_montant.order(created_at: :desc)

    # Planning preview
    @latest_quote = @project.property&.quotes&.includes(:quote_items)&.order(created_at: :desc)&.first
    @planning_items_count = @latest_quote ? @latest_quote.quote_items.count : 0
    @factures_count = @project.factures.count
    @simulations = @project.simulations.order(created_at: :desc)
  end

  def new
    @project = current_user.projects.build
    @project.project_type = params[:project_type] if params[:project_type].present?
  end

  def create
    @project = Project.new(project_params)
    @project.user = current_user

    if @project.save
      message = @project.investment? ? 'Investissement créé avec succès.' : 'Chantier créé avec succès.'
      redirect_to @project, notice: message
    else
      Rails.logger.error "Project validation errors: #{@project.errors.full_messages}"
      flash.now[:alert] = "Erreurs de validation : #{@project.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def edit_budget
    @devis_donnees        = @project.devis_donnees.includes(:document).order(created_at: :desc)
    @bordereaux_chassis   = @project.bordereau_chassis_donnees.includes(:document).order(created_at: :desc)
    @factures             = @project.factures.includes(:document).order(date_facture: :desc)
  end

  def edit_professionals
  end

  def update_professionals
    tva_avant = @project.entrepreneur_principal_numero_tva
    if @project.update(professionals_params)
      # Relancer la vérification BCE si le N° TVA a changé
      tva_apres = @project.entrepreneur_principal_numero_tva
      if tva_apres.present? && tva_apres != tva_avant
        @project.update_columns(entrepreneur_bce_statut: nil, entrepreneur_bce_verifie_at: nil)
        BceVerificationJob.perform_later(@project.id)
      end
      redirect_to @project, notice: 'Équipe projet mise à jour avec succès.'
    else
      render :edit_professionals, status: :unprocessable_entity
    end
  end

  def update_budget
    if @project.update(budget_params)
      redirect_to @project, notice: 'Budget mis à jour avec succès.'
    else
      render :edit_budget, status: :unprocessable_entity
    end
  end

  def update
    # Traitement spécial pour les entrepreneurs additionnels
    if params[:additional_entrepreneurs].present?
      additional_entrepreneurs_data = params[:additional_entrepreneurs].map do |entrepreneur|
        entrepreneur.permit(:nom, :entreprise, :numero_tva, :telephone, :email, :adresse, :assurance, :specialite, :devis_montant)
      end
      @project.additional_entrepreneurs = additional_entrepreneurs_data.to_json
    end

    # Suivi historique du permis d'urbanisme
    nouveau_statut = project_params[:permis_urbanisme_statut]
    if nouveau_statut.present? && nouveau_statut != @project.permis_urbanisme_statut
      historique = (@project.permis_urbanisme_historique || []).dup
      historique << { statut: nouveau_statut, changed_at: Time.current.iso8601, user_id: current_user.id }
      @project.permis_urbanisme_historique = historique
    end

    if @project.update(project_params)
      message = @project.investment? ? 'Investissement mis à jour avec succès.' : 'Chantier mis à jour avec succès.'
      redirect_to @project, notice: message
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    project_name = @project.nom
    project_type = @project.investment? ? "l'investissement" : "le chantier"

    begin
      @project.destroy
      redirect_to projects_path, notice: "#{project_type.capitalize} '#{project_name}' a été supprimé avec succès."
    rescue => e
      redirect_to @project, alert: "Erreur lors de la suppression #{project_type.gsub('l\'', 'd\'un ')} : #{e.message}"
    end
  end

  # POST /projects/:id/scan_attestation_conformite
  def scan_attestation_conformite
    unless params[:file].present?
      return render json: { error: 'Aucun fichier fourni' }, status: :bad_request
    end

    begin
      service = AttestationConformiteOcrService.new(params[:file])
      result  = service.extraire_donnees_attestation

      unless result[:success]
        return render json: { error: result[:error] }, status: :unprocessable_entity
      end

      # Résumé lisible pour le champ notes
      statut_txt = AttestationConformiteOcrService.label_resultat(result[:resultat])[:label]
      notes_txt  = [statut_txt,
                    result[:organisme_controleur],
                    result[:date_controle]&.strftime('%d/%m/%Y'),
                    result[:numero_rapport].present? ? "N°#{result[:numero_rapport]}" : nil
                   ].compact.join(' — ')

      document = current_user.documents.create!(
        file:              params[:file],
        type_document:     'attestation_conformite',
        property:          @project.property,
        status:            result[:extraction_complete] ? 'approved' : 'pending',
        notes:             notes_txt,
        donnees_extraites: {
          'organisme_controleur'   => result[:organisme_controleur],
          'date_controle'          => result[:date_controle]&.iso8601,
          'resultat'               => result[:resultat],
          'numero_rapport'         => result[:numero_rapport],
          'date_prochain_controle' => result[:date_prochain_controle]&.iso8601,
          'installateur'           => result[:installateur],
          'type_controle'          => result[:type_controle],
          'confiance_ocr'          => result[:confiance_ocr],
          'extraction_complete'    => result[:extraction_complete]
        }
      )

      # Rattacher le document au projet
      @project.documents << document unless @project.documents.include?(document)

      if document.file.attached? && document.file_url.blank?
        document.update_column(:file_url, rails_blob_url(document.file))
      end

      render json: {
        success:                true,
        document_id:            document.id,
        organisme_controleur:   result[:organisme_controleur],
        date_controle:          result[:date_controle]&.strftime('%d/%m/%Y'),
        resultat:               result[:resultat],
        numero_rapport:         result[:numero_rapport],
        date_prochain_controle: result[:date_prochain_controle]&.strftime('%d/%m/%Y'),
        installateur:           result[:installateur],
        type_controle:          result[:type_controle],
        confiance_ocr:          result[:confiance_ocr],
        extraction_complete:    result[:extraction_complete]
      }

    rescue ActiveRecord::RecordInvalid => e
      render json: { error: 'Erreur sauvegarde', details: e.record.errors.full_messages }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "scan_attestation_conformite error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      render json: { error: 'Erreur lors du traitement', details: Rails.env.development? ? e.message : nil }, status: :internal_server_error
    end
  end

  def reception_chantier
    property = @project.property

    # ── PEB avant / après ───────────────────────────────────────────────────
    @peb_apres  = @project.peb_donnees.includes(:document).order(created_at: :desc)
    @peb_avant  = property&.peb_donnees&.avant_travaux&.order(created_at: :desc)&.first
    @peb_actuel = @peb_apres.first

    # ── Analyse politique régionale (si label disponible) ───────────────────
    region = @peb_actuel&.region || @peb_avant&.region || property&.region&.downcase
    @region = region
    @analyse_politique = if @peb_actuel&.label_peb.present? && region.present?
                           PebPolitiqueRegionale.analyse(
                             region:        region,
                             label_actuel:  @peb_actuel.label_peb,
                             label_avant:   @peb_avant&.label_peb,
                             date_validite: @peb_actuel.date_validite
                           )
                         end

    # ── Bilan financier ─────────────────────────────────────────────────────
    @factures = @project.factures.includes(:document).order(nom_entreprise: :asc, date_facture: :asc)
    @factures_par_entreprise = @factures.travaux_only.group_by(&:nom_entreprise)

    @total_architecte_devis   = @project.architecte_devis_montant.to_f
    @total_architecte_factures = @project.architecte_factures_total
    @total_entrepreneur_devis   = @project.contractor_devis_montant.to_f
    @total_entrepreneur_factures = @project.contractor_factures_total
    @total_devis     = @total_architecte_devis + @total_entrepreneur_devis
    @total_factures  = @total_architecte_factures + @total_entrepreneur_factures
    @solde_total     = @total_factures - @total_devis

    # ── Documents de réception — checklist ──────────────────────────────────
    docs = @project.documents.includes(:peb_donnee).order(created_at: :desc)
    @docs_peb_apres      = docs.where(type_document: 'certificat_peb_apres')
    @docs_conformite     = docs.where(type_document: 'attestation_conformite')
    @docs_attestation    = docs.where(type_document: 'attestation_entrepreneur')
    @docs_etat_avancement = docs.where(type_document: 'etat_avancement')
    @docs_photos_apres   = docs.where(type_document: 'photo_apres').limit(6)

    # Checklist items : [libellé, présent?, doc, lien_action]
    @checklist = [
      {
        cle:      :peb_apres,
        icone:    'bi-file-earmark-bar-graph',
        titre:    "Certificat PEB après travaux",
        obligatoire: true,
        present:  @docs_peb_apres.any? || @peb_apres.any?,
        note:     "Obligatoire pour les demandes de primes et toute vente / location.",
        action:   fin_chantier_project_path(@project)
      },
      {
        cle:      :conformite_electrique,
        icone:    'bi-lightning-charge',
        titre:    "Attestation de conformité électrique (RGIE)",
        obligatoire: true,
        present:  @docs_conformite.any?,
        note:     "Obligatoire si des travaux électriques ont été réalisés.",
        action:   nil
      },
      {
        cle:      :etat_avancement,
        icone:    'bi-list-check',
        titre:    "État d'avancement / PV de réception",
        obligatoire: false,
        present:  @docs_etat_avancement.any?,
        note:     "Procès-verbal de réception signé par l'entrepreneur.",
        action:   nil
      },
      {
        cle:      :photos_apres,
        icone:    'bi-camera',
        titre:    "Photos après travaux",
        obligatoire: false,
        present:  @docs_photos_apres.any?,
        note:     "Photos des postes rénovés (toiture, murs, châssis, chauffage...).",
        action:   photos_documents_path
      },
      {
        cle:      :attestation_entrepreneur,
        icone:    'bi-person-badge',
        titre:    "Attestation(s) entrepreneur",
        obligatoire: false,
        present:  @docs_attestation.any?,
        note:     "Attestation TVA 6% et/ou mentions légales type.",
        action:   nil
      }
    ]

    @nb_presents   = @checklist.count { |c| c[:present] }
    @nb_obligatoires_ok = @checklist.count { |c| c[:obligatoire] && c[:present] }
    @nb_obligatoires    = @checklist.count { |c| c[:obligatoire] }
    @completion_pct = (@nb_presents.to_f / @checklist.size * 100).round

    # Réserves de réception
    @reserves = @project.reserves.order(statut: :asc, created_at: :desc)

    # Plans disponibles pour annotations (documents de type :plan attachés au projet)
    @plan_documents = @project.documents.where(type_document: 'plan').includes(file_attachment: :blob)

    # Checklists d'inspection
    @project_checklists   = @project.project_checklists
                                     .includes(:checklist_template)
                                     .order(created_at: :desc)
    @checklist_templates  = ChecklistTemplate.ordered
  end

  # GET /projects/:id/garanties
  def garanties
    date_fin = @project.work_completion_date || @project.date_fin

    # Documents garanties
    docs = @project.documents.order(created_at: :desc)
    @docs_garantie          = docs.where(type_document: 'certificat_garantie')
    @docs_assurance_dec     = docs.where(type_document: 'assurance_decennale')
    @docs_assurance_rc      = docs.where(type_document: 'assurance_rc_pro')

    # Construire la liste des entrepreneurs depuis toutes les sources
    entrepreneurs = []

    # 1. Entrepreneur principal
    if @project.entrepreneur_principal_entreprise.present? || @project.entrepreneur_principal_nom.present?
      entrepreneurs << {
        nom:       @project.entrepreneur_principal_nom,
        entreprise: @project.entrepreneur_principal_entreprise,
        tva:       @project.entrepreneur_principal_numero_tva,
        email:     @project.entrepreneur_principal_email,
        telephone: @project.entrepreneur_principal_telephone,
        source:    :principal
      }
    end

    # 2. Entrepreneurs additionnels (JSON)
    if @project.additional_entrepreneurs.present?
      begin
        extra = JSON.parse(@project.additional_entrepreneurs)
        extra.each do |e|
          next unless e['entreprise'].present? || e['nom'].present?
          entrepreneurs << {
            nom:       e['nom'],
            entreprise: e['entreprise'],
            tva:       e['numero_tva'],
            email:     e['email'],
            telephone: e['telephone'],
            source:    :additionnel
          }
        end
      rescue JSON::ParserError
      end
    end

    # 3. Entreprises issues des factures (non déjà présentes)
    noms_factures = @project.factures.pluck(:nom_entreprise).uniq.compact
    noms_factures.each do |nom|
      next if entrepreneurs.any? { |e| e[:entreprise]&.downcase == nom.downcase || e[:nom]&.downcase == nom.downcase }
      entrepreneurs << { nom: nil, entreprise: nom, tva: nil, email: nil, telephone: nil, source: :facture }
    end

    @entrepreneurs = entrepreneurs

    # Calculer les garanties par entrepreneur
    @garanties_par_entrepreneur = @entrepreneurs.map do |ent|
      nom_affiche = ent[:entreprise].presence || ent[:nom] || 'Entreprise inconnue'
      {
        entrepreneur:  ent,
        nom_affiche:   nom_affiche,
        decennale: {
          duree: 10,
          debut: date_fin,
          fin:   date_fin ? date_fin + 10.years : nil
        },
        biennale: {
          duree: 2,
          debut: date_fin,
          fin:   date_fin ? date_fin + 2.years : nil
        },
        bon_fonctionnement: {
          duree: 1,
          debut: date_fin,
          fin:   date_fin ? date_fin + 1.year : nil
        }
      }
    end

    @date_fin_travaux = date_fin
  end

  # POST /projects/:id/check_contrat (IA #9 — Analyse clauses contrat)
  def check_contrat
    unless params[:file].present?
      return render json: { error: 'Aucun fichier fourni' }, status: :bad_request
    end

    # Extraction texte via OCR
    ocr = OcrService.new(params[:file])
    ocr_result = ocr.call

    unless ocr_result[:success]
      return render json: { error: "Extraction texte impossible : #{ocr_result[:error]}" },
                    status: :unprocessable_entity
    end

    texte = ocr_result[:text].to_s
    if texte.strip.length < 50
      return render json: { error: 'Texte extrait trop court — vérifiez que le fichier est lisible.' },
                    status: :unprocessable_entity
    end

    analyse = ContratChecklistService.new(texte).analyser
    render json: analyse
  rescue StandardError => e
    Rails.logger.error "check_contrat error: #{e.message}\n#{e.backtrace.first(3).join("\n")}"
    render json: { error: 'Erreur lors de l\'analyse' }, status: :internal_server_error
  end

  # GET /projects/:id/carnet_entretien
  def carnet_entretien
    docs = @project.documents.order(created_at: :desc)

    # Documents DIU
    @docs_diu       = docs.where(type_document: 'plan_diu')
    @docs_notices   = docs.where(type_document: 'notice_equipement')
    @docs_fiches    = docs.where(type_document: 'fiche_technique')
    @docs_secu      = docs.where(type_document: 'fiche_securite_materiaux')
    @docs_entretien = docs.where(type_document: 'instruction_entretien')

    # Rappels maintenance selon les types de travaux
    @rappels_maintenance = generer_rappels_maintenance

    # Contacts intervenants (architecte + entrepreneurs)
    @contacts = []
    if @project.architecte_nom.present? || @project.architecte_entreprise.present?
      @contacts << {
        role:      'Architecte',
        icone:     'bi-person-badge',
        couleur:   'primary',
        nom:       [@project.architecte_prenom, @project.architecte_nom].compact.join(' '),
        entreprise: @project.architecte_entreprise,
        telephone: @project.architecte_telephone,
        email:     @project.architecte_email
      }
    end
    if @project.entrepreneur_principal_entreprise.present? || @project.entrepreneur_principal_nom.present?
      @contacts << {
        role:      'Entrepreneur principal',
        icone:     'bi-tools',
        couleur:   'warning',
        nom:       @project.entrepreneur_principal_nom,
        entreprise: @project.entrepreneur_principal_entreprise,
        telephone: @project.entrepreneur_principal_telephone,
        email:     @project.entrepreneur_principal_email
      }
    end
    if @project.additional_entrepreneurs.present?
      begin
        JSON.parse(@project.additional_entrepreneurs).each do |e|
          next unless e['entreprise'].present? || e['nom'].present?
          @contacts << {
            role:      e['specialite'].presence || 'Entrepreneur',
            icone:     'bi-hammer',
            couleur:   'secondary',
            nom:       e['nom'],
            entreprise: e['entreprise'],
            telephone: e['telephone'],
            email:     e['email']
          }
        end
      rescue JSON::ParserError
      end
    end
    # Ajouter aussi les entreprises des factures non encore listées
    noms_connus = @contacts.map { |c| c[:entreprise]&.downcase }.compact
    @project.factures.pluck(:nom_entreprise).uniq.compact.each do |nom|
      next if noms_connus.include?(nom.downcase)
      @contacts << { role: 'Entrepreneur (facture)', icone: 'bi-receipt', couleur: 'secondary',
                     nom: nil, entreprise: nom, telephone: nil, email: nil }
    end
  end

  def fin_chantier
    @peb_apres = @project.peb_donnees.includes(:document).order(created_at: :desc)
    @peb_avant = @project.property&.peb_donnees&.avant_travaux&.order(created_at: :desc)&.first

    region = @peb_apres.first&.region ||
             @peb_avant&.region ||
             @project.property&.region&.downcase

    peb_actuel = @peb_apres.first
    @analyse_politique = if peb_actuel&.label_peb.present? && region.present?
                           PebPolitiqueRegionale.analyse(
                             region:        region,
                             label_actuel:  peb_actuel.label_peb,
                             label_avant:   @peb_avant&.label_peb,
                             date_validite: peb_actuel.date_validite
                           )
                         elsif region.present?
                           PebPolitiqueRegionale.contexte_regional(region)
                         end

    @region = region
    @upload_peb_url = scan_peb_apres_project_url(@project)
  end

  # POST /projects/:id/scan_peb_apres
  def scan_peb_apres
    unless params[:file].present?
      return render json: { error: 'Aucun fichier fourni' }, status: :bad_request
    end

    begin
      peb_service = PebOcrService.new(params[:file])
      result      = peb_service.extraire_donnees_peb

      unless result[:success]
        return render json: { error: result[:error] }, status: :unprocessable_entity
      end

      # Document
      document = current_user.documents.create!(
        file:          params[:file],
        type_document: 'certificat_peb_apres',
        property:      @project.property,
        status:        'pending',
        notes:         "Certificat PEB après travaux — projet #{@project.nom} " \
                       "— #{result[:region]&.capitalize} — confiance #{result[:confiance_ocr].to_i} %"
      )

      if document.file.attached? && document.file_url.blank?
        document.update_column(:file_url, rails_blob_url(document.file))
      end

      # PebDonnee rattachée au projet (phase: apres_travaux)
      peb_donnee = PebDonnee.create!(
        property:            @project.property,
        project:             @project,
        document:            document,
        user:                current_user,
        phase:               'apres_travaux',
        region:              result[:region],
        numero_certificat:   result[:numero_certificat],
        label_peb:           result[:label_peb],
        score_ep:            result[:score_ep],
        surface_reference:   result[:surface_reference],
        date_certificat:     result[:date_certificat],
        date_validite:       result[:date_validite],
        confiance_ocr:       result[:confiance_ocr],
        extraction_complete: result[:extraction_complete],
        texte_ocr_brut:      result[:texte_ocr_brut],
        donnees_extraites:   { 'recommandations' => result[:recommandations] || [] }
      )

      # MAJ automatique du champ date_peb_apres_travaux si suffisamment fiable
      if @project.property && result[:confiance_ocr].to_i >= 70 && result[:date_certificat].present?
        @project.property.update_column(:date_peb_apres_travaux, result[:date_certificat])
      end

      render json: {
        success:             true,
        document_id:         document.id,
        peb_donnee_id:       peb_donnee.id,
        region:              result[:region],
        numero_certificat:   result[:numero_certificat],
        label_peb:           result[:label_peb],
        score_ep:            result[:score_ep],
        surface_reference:   result[:surface_reference],
        date_certificat:     result[:date_certificat]&.strftime('%d/%m/%Y'),
        date_validite:       result[:date_validite]&.strftime('%d/%m/%Y'),
        confiance_ocr:       result[:confiance_ocr],
        extraction_complete: result[:extraction_complete]
      }

    rescue ActiveRecord::RecordInvalid => e
      render json: { error: "Erreur sauvegarde PEB", details: e.record.errors.full_messages }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "scan_peb_apres error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      render json: { error: "Erreur lors du traitement du certificat PEB", details: Rails.env.development? ? e.message : nil }, status: :internal_server_error
    end
  end

  # POST /projects/:id/scan_audit_energ
  def scan_audit_energ
    unless params[:file].present?
      return render json: { error: 'Aucun fichier fourni' }, status: :bad_request
    end

    unless @project.property&.region == 'wallonie'
      return render json: { error: "L'audit énergétique Walloreno est réservé aux biens wallons" }, status: :unprocessable_entity
    end

    begin
      service = AuditEnergOcrService.new(params[:file])
      result  = service.extraire_donnees_audit

      unless result[:success]
        return render json: { error: result[:error] }, status: :unprocessable_entity
      end

      document = current_user.documents.create!(
        file:          params[:file],
        type_document: 'rapport_audit_energetique',
        property:      @project.property,
        project:       @project,
        status:        'pending',
        notes:         "Audit énergétique Walloreno — #{result[:numero_audit]} " \
                       "— auditeur #{result[:numero_pae]} — confiance #{result[:confiance_ocr].to_i} %"
      )

      if document.file.attached? && document.file_url.blank?
        document.update_column(:file_url, rails_blob_url(document.file))
      end

      audit = AuditEnergDonnee.create!(
        document:             document,
        user:                 current_user,
        property:             @project.property,
        project:              @project,
        numero_audit:         result[:numero_audit],
        date_enregistrement:  result[:date_enregistrement],
        numero_pae:           result[:numero_pae],
        denomination_auditeur: result[:denomination_auditeur],
        adresse_auditeur:     result[:adresse_auditeur],
        label_initial:        result[:label_initial],
        label_final:          result[:label_final],
        recommandations_json: result[:recommandations_json] || [],
        bilan_json:           result[:bilan_json] || {},
        confiance_ocr:        result[:confiance_ocr],
        extraction_complete:  result[:extraction_complete],
        texte_ocr_brut:       result[:texte_ocr_brut]
      )

      # Synchroniser le numéro d'audit sur le projet si absent
      if @project.numero_audit.blank? && result[:numero_audit].present?
        @project.update_column(:numero_audit, result[:numero_audit])
      end
      if @project.numero_agrement_auditeur.blank? && result[:numero_pae].present?
        @project.update_column(:numero_agrement_auditeur, result[:numero_pae])
      end

      render json: {
        success:              true,
        audit_id:             audit.id,
        document_id:          document.id,
        numero_audit:         result[:numero_audit],
        date_enregistrement:  result[:date_enregistrement]&.strftime('%d/%m/%Y'),
        numero_pae:           result[:numero_pae],
        denomination_auditeur: result[:denomination_auditeur],
        label_initial:        result[:label_initial],
        label_final:          result[:label_final],
        nb_recommandations:   (result[:recommandations_json] || []).size,
        confiance_ocr:        result[:confiance_ocr],
        extraction_complete:  result[:extraction_complete]
      }

    rescue ActiveRecord::RecordInvalid => e
      render json: { error: "Erreur sauvegarde audit", details: e.record.errors.full_messages }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "scan_audit_energ error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      render json: { error: "Erreur lors du traitement de l'audit", details: Rails.env.development? ? e.message : nil }, status: :internal_server_error
    end
  end

  def update_fin_chantier
    # réservé pour future mise à jour manuelle (notes, validation)
    redirect_to fin_chantier_project_path(@project), notice: "Données fin de chantier mises à jour."
  end

  def gantt
    @quotes = @project.property.quotes.includes(:quote_items).order(created_at: :desc)
    @latest_quote = @quotes.first
    @factures = @project.factures.order(:date_facture)

    # Date de début : date_début du projet ou aujourd'hui
    @start_date = @project.date_début || Date.today

    # Construire les barres Gantt depuis le dernier devis
    @gantt_bars = build_gantt_bars(@start_date, @latest_quote)

    # Jalons : date début, factures, date fin
    @milestones = build_milestones
  end

  def roi_calculator
    # Détail devis (OCR ou manuels)
    @devis_architecte   = (@project.architecte_devis_montant_effectif || 0).to_f
    @devis_entrepreneur = (@project.contractor_devis_montant_effectif || 0).to_f

    # Détail factures
    @factures_architecte   = (@project.architecte_factures_total || 0).to_f
    @factures_entrepreneur = (@project.contractor_factures_total || 0).to_f
    total_factures         = @factures_architecte + @factures_entrepreneur

    # Coût : total factures si disponibles, sinon total devis
    total_devis   = @devis_architecte + @devis_entrepreneur
    @cout_travaux = (total_factures > 0 ? total_factures : total_devis).to_f
    @cout_source  = total_factures > 0 ? :factures : (total_devis > 0 ? :devis : :vide)

    # Primes : dernière simulation du projet si elle existe
    @primes_estimees = @project.simulations
                               .order(created_at: :desc)
                               .first
                               &.total_primes_amount
                               &.to_f || 0.0

    # Valeur d'achat du bien (seule valeur disponible en base)
    @property    = @project.property
    @valeur_bien = (@property&.valeur_achat || 0).to_f
  end

  # POST /projects/:id/analyze_photos
  # Lance l'analyse IA des photos en arrière-plan
  def analyze_photos
    photos_count = @project.documents.where(type_document: %w[photo_avant photo_pendant photo_apres photo_chassis]).count

    if photos_count.zero?
      return render json: { success: false, error: 'Aucune photo de chantier disponible' }, status: :unprocessable_entity
    end

    ChantierVisionJob.perform_later(@project.id)
    render json: { success: true, message: 'Analyse lancée, résultat disponible dans quelques secondes', photos_count: photos_count }
  end

  # GET /projects/:id/vision_status
  # Retourne le dernier résultat d'analyse IA + historique
  def vision_status
    if @project.vision_analysis.present?
      history = @project.chantier_analyses.recent_first.limit(10).map do |a|
        {
          id:           a.id,
          avancement:   a.avancement,
          phase:        a.phase,
          photos_count: a.photos_count,
          analysed_at:  a.analysed_at
        }
      end
      render json: {
        success:      true,
        analysed_at:  @project.vision_analysed_at,
        analysis:     @project.vision_analysis,
        history:      history
      }
    else
      render json: { success: false, pending: true }
    end
  end

  # IA #3 — Score Santé Projet /10
  def score_sante
    result = ProjectHealthScoreService.new(@project).call
    render json: result
  end

  # PATCH /projects/:id/validate_phase
  # Validation 3-parties : propriétaire, architecte, entrepreneur
  CHANTIER_PHASES = %w[phase_preparation phase_demolition phase_installation phase_finition phase_reception].freeze

  def validate_phase
    phase_key = params[:phase_key].to_s
    unless CHANTIER_PHASES.include?(phase_key)
      redirect_back fallback_location: pro_view_project_path(@project), alert: "Phase invalide." and return
    end

    # Déterminer le rôle du validateur
    role = if @project.user_id == current_user.id
             'owner'
           elsif @project.project_members.active.where(user: current_user, role: 'architect').exists?
             'architect'
           elsif @project.project_members.active.where(user: current_user, role: 'entrepreneur').exists?
             'entrepreneur'
           end

    unless role
      redirect_back fallback_location: pro_view_project_path(@project), alert: "Non autorisé." and return
    end

    avancement = @project.phases_avancement.dup
    phase_data = (avancement[phase_key] || {}).dup

    # Structure V2 : chaque rôle a sa propre validation
    # Rétrocompatibilité : si ancienne structure (validated_at à la racine), on migre
    if phase_data['validated_at'].present? && phase_data['owner'].nil? && phase_data['architect'].nil?
      phase_data = { 'owner' => { 'validated_at' => phase_data['validated_at'], 'validated_by' => phase_data['validated_by'] } }
    end

    if phase_data[role].present?
      redirect_back fallback_location: pro_view_project_path(@project),
                    notice: "Vous avez déjà validé cette phase." and return
    end

    phase_data[role] = { 'validated_at' => Time.current.iso8601, 'validated_by' => current_user.id }
    avancement[phase_key] = phase_data
    @project.update!(phases_avancement: avancement)

    # Message selon rôle et nombre de validations
    role_label = { 'owner' => 'Propriétaire', 'architect' => 'Architecte', 'entrepreneur' => 'Entrepreneur' }[role]
    validation_count = phase_data.keys.count
    all_roles_present = determine_required_roles.all? { |r| phase_data[r].present? }

    notice = if all_roles_present
               "Phase « #{phase_key.delete_prefix('phase_').humanize} » validée par les 3 parties ✓"
             else
               "#{role_label} : phase « #{phase_key.delete_prefix('phase_').humanize} » validée (#{validation_count}/#{determine_required_roles.size})"
             end

    redirect_back fallback_location: pro_view_project_path(@project), notice: notice
  end

  private

  def determine_required_roles
    roles = ['owner']
    roles << 'architect'    if @project.project_members.active.where(role: 'architect').exists?
    roles << 'entrepreneur' if @project.project_members.active.where(role: 'entrepreneur').exists?
    roles
  end

  def generer_rappels_maintenance
    type = @project.type_travaux.to_s.downcase
    date_fin = @project.work_completion_date || @project.date_fin

    rappels = []

    # Chaudière / chauffage
    if type.include?('chauffage') || type.include?('boiler') || type.include?('chaudière') || type.include?('pompe')
      rappels << { categorie: 'Chauffage', icone: 'bi-thermometer-half', couleur: 'warning',
                   equipement: 'Chaudière / Pompe à chaleur', frequence: 'Annuel',
                   prochaine: date_fin ? (date_fin + 1.year) : nil, note: 'Entretien annuel obligatoire (AR 12/10/2010)' }
    end

    # Ventilation / VMC
    if type.include?('ventilat') || type.include?('vmc') || type.include?('ventilatiesysteem')
      rappels << { categorie: 'Ventilation', icone: 'bi-wind', couleur: 'info',
                   equipement: 'VMC / Système de ventilation', frequence: 'Annuel',
                   prochaine: date_fin ? (date_fin + 1.year) : nil, note: 'Nettoyage filtres, vérification débits' }
    end

    # Toiture
    if type.include?('toiture') || type.include?('toit') || type.include?('dak')
      rappels << { categorie: 'Toiture', icone: 'bi-house-fill', couleur: 'secondary',
                   equipement: 'Toiture / Couverture', frequence: 'Tous les 5 ans',
                   prochaine: date_fin ? (date_fin + 5.years) : nil, note: 'Inspection, nettoyage gouttières, contrôle noues' }
    end

    # Panneaux solaires / PV
    if type.include?('solaire') || type.include?('photovolt') || type.include?('panneaux pv')
      rappels << { categorie: 'Énergie solaire', icone: 'bi-sun', couleur: 'warning',
                   equipement: 'Panneaux photovoltaïques', frequence: 'Annuel',
                   prochaine: date_fin ? (date_fin + 1.year) : nil, note: 'Nettoyage, vérification onduleur et connexions' }
    end

    # Châssis / fenêtres
    if type.include?('ch\u00e2ssis') || type.include?('fen\u00eatre') || type.include?('schrijnwerk')
      rappels << { categorie: 'Menuiseries', icone: 'bi-window', couleur: 'secondary',
                   equipement: 'Châssis / Fenêtres / Portes', frequence: 'Tous les 2 ans',
                   prochaine: date_fin ? (date_fin + 2.years) : nil, note: 'Graissage joints, réglage ferrage, vérification étanchéité' }
    end

    # Rappels généraux toujours présents
    rappels << { categorie: 'Électricité', icone: 'bi-lightning-charge', couleur: 'danger',
                 equipement: 'Installation électrique', frequence: 'Tous les 25 ans',
                 prochaine: date_fin ? (date_fin + 25.years) : nil, note: 'Renouvellement obligatoire contrôle RGIE (AR 2019)' }
    rappels << { categorie: 'Peintures / finitions', icone: 'bi-brush', couleur: 'secondary',
                 equipement: 'Façades, peintures intérieures', frequence: 'Tous les 10 ans',
                 prochaine: date_fin ? (date_fin + 10.years) : nil, note: 'Selon exposition et qualité des matériaux' }

    rappels.sort_by { |r| r[:prochaine] || Date.today + 99.years }
  end

  def build_gantt_bars(start_date, quote)
    return [] unless quote

    cursor = start_date
    bars = []

    quote.quote_items.each do |item|
      wt = WorkType.find(item.work_type_key)
      next unless wt

      duration = item.unit_price_min.present? ? (wt.duration_min + wt.duration_max) / 2.0 : wt.duration_min
      end_date = cursor + duration.ceil.days

      bars << {
        key:      item.work_type_key,
        name:     wt.name,
        icon:     wt.icon,
        category: wt.category,
        start:    cursor,
        end:      end_date,
        total_min: item.total_min,
        total_max: item.total_max,
        total_avg: item.total_avg || ((item.total_min.to_f + item.total_max.to_f) / 2).round(2)
      }

      # Chevauchement léger : démarrage du suivant à J+2 du début (travaux parallèles possibles)
      cursor = cursor + 2.days
    end

    bars
  end

  def build_milestones
    milestones = []
    milestones << { date: @project.date_début, label: 'Début chantier', color: 'success' } if @project.date_début
    @factures.each do |f|
      next unless f.date_facture
      milestones << { date: f.date_facture, label: "Facture #{f.type_facture&.humanize}", color: 'warning' }
    end
    milestones << { date: @project.date_fin, label: 'Fin prévue', color: 'danger' } if @project.date_fin
    milestones.sort_by { |m| m[:date] }
  end

  def set_project
    @project = current_user.projects.find(params[:id])
  end

  def budget_params
    params.require(:project).permit(:architecte_devis_montant, :contractor_devis_montant)
  end

  def professionals_params
    params.require(:project).permit(
      :architecte_nom, :architecte_prenom, :architecte_entreprise, :architecte_numero_ordre,
      :architecte_telephone, :architecte_email, :architecte_adresse, :architecte_specialites,
      :entrepreneur_principal_nom, :entrepreneur_principal_entreprise, :entrepreneur_principal_numero_tva,
      :entrepreneur_principal_telephone, :entrepreneur_principal_email, :entrepreneur_principal_adresse,
      :entrepreneur_principal_assurance, :entrepreneur_principal_certifications,
      :maitre_ouvrage_nom, :maitre_ouvrage_contact, :coordinateur_securite_nom, :coordinateur_securite_contact,
      :assurance_decennale_architecte, :assurance_decennale_entrepreneur, :garanties_travaux,
      :additional_entrepreneurs
    )
  end

  def project_params
    params.require(:project).permit(
      :nom, :description, :date_début, :date_fin, :statut, :property_id, :project_type,
      :bce_number, :invoice_date, :work_completion_date,
      # Champs spécifiques Flandre
      :type_travaux, :reconstruction_demolition, :tva_reduit_6_pourcent,
      # Checkboxes pour types de travaux Flandre
      :type_travaux_isolation, :type_travaux_chauffage, :type_travaux_ventilation,
      :type_travaux_fenetres, :type_travaux_toiture, :type_travaux_autre,
      # Champs architecte
      :architecte_nom, :architecte_prenom, :architecte_entreprise, :architecte_numero_ordre,
      :architecte_telephone, :architecte_email, :architecte_adresse, :architecte_specialites,
      # Champs entrepreneur principal
      :entrepreneur_principal_nom, :entrepreneur_principal_entreprise, :entrepreneur_principal_numero_tva,
      :entrepreneur_principal_telephone, :entrepreneur_principal_email, :entrepreneur_principal_adresse,
      :entrepreneur_principal_assurance, :entrepreneur_principal_certifications,
      # Champs montants de devis
      :architecte_devis_montant, :contractor_devis_montant,
      # Champs autres professionnels
      :maitre_ouvrage_nom, :maitre_ouvrage_contact, :coordinateur_securite_nom, :coordinateur_securite_contact,
      # Champs assurances
      :assurance_decennale_architecte, :assurance_decennale_entrepreneur, :garanties_travaux,
      # Champs permis d'urbanisme
      :permis_urbanisme_statut, :permis_urbanisme_number, :permis_urbanisme_date,
      :permis_urbanisme_autorite, :permis_urbanisme_notes,
      # Champs audit énergétique (Wallonie)
      :numero_audit, :date_audit, :numero_agrement_auditeur, :prix_audit,
      # Corps de métiers (JSON)
      :corps_metiers,
      # Entrepreneurs additionnels
      :additional_entrepreneurs,
      # Keyword args (arrays/hashes) — doivent être en dernier
      additional_entrepreneurs: [],
      permis_urbanisme_historique: [],
      # Avancement des phases de chantier
      phases_avancement: {}
    )
  end
end
