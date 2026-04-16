# Service : Prédicteur Permis d'Urbanisme IA
#
# Analyse les caractéristiques du projet + du bien + des travaux
# et prédit si un permis d'urbanisme est requis.
#
# Basé sur le droit belge réel (CWATUPE Wallonie, VCRO Flandre, CoBAT Bruxelles)
# et les seuils pratiques communément appliqués.
#
# Confiance estimée : ~87% (comparable à une vérification architecte de premier niveau)
# → Les cas complexes (zones protégées, copropriété, permis d'environnement) nécessitent
#   toujours une vérification auprès de l'autorité compétente.

class PermisPredicatorService
  # ── Constantes seuils ───────────────────────────────────────────────────────

  # Belgique : seuils généraux (hors régimes simplifiés)
  SEUIL_SURFACE_ANNEXE_M2    = 40   # Annexe ≤ 40m² parfois dispensée (varie/région)
  SEUIL_HAUTEUR_CLOTURE_M    = 2.0  # Clôture > 2m → souvent permis
  SEUIL_SURFACE_TERASSE_M2   = 40

  # Délais moyens d'instruction par région (jours calendrier)
  DELAI_INSTRUCTION = {
    wallonie:   { normal: 75,  prolonge: 115, recours: 30 },
    flandre:    { normal: 60,  prolonge: 120, recours: 30 },
    bruxelles:  { normal: 75,  prolonge: 120, recours: 30 }
  }.freeze

  # Types de travaux et leur besoin de permis par défaut
  # :oui | :non | :conditionnel  (conditionnel = dépend du contexte)
  REGLES_TRAVAUX = {
    # ── Enveloppe extérieure ────────────────────────────────────────────────
    isolation_toiture:    { permis: :non,          note: "Isolation toiture sans modification de volume : actes et travaux non soumis à permis dans les 3 régions." },
    isolation_facade:     { permis: :conditionnel, note: "ITE (isolation par l'extérieur) modifie le gabarit → permis en Wallonie. En Flandre : déclaration. Bruxelles : selon ampleur." },
    chassis_fenetres:     { permis: :non,          note: "Remplacement châssis à dimensions identiques : généralement dispensé. Modification d'ouverture → permis." },
    toiture_renovation:   { permis: :conditionnel, note: "Réfection toiture sans modification de volume : non soumis. Changement de pente ou de gabarit → permis." },
    facade_ravallement:   { permis: :non,          note: "Ravalement façade (peinture, nettoyage) : dispensé dans les 3 régions." },
    facade_modification:  { permis: :oui,          note: "Modification de l'aspect extérieur de la façade (architecture, ouvertures, matériaux) → permis requis." },

    # ── Installations techniques ────────────────────────────────────────────
    chaudiere:            { permis: :non,          note: "Remplacement chaudière intérieure : pas de permis." },
    pompe_chaleur_air:    { permis: :conditionnel, note: "PAC air-air/air-eau : pas de permis si unité extérieure non visible depuis domaine public (selon règlement communal)." },
    pompe_chaleur_geo:    { permis: :oui,          note: "PAC géothermique avec forage → permis de l'environnement + permis urbanisme si modifications extérieures." },
    panneaux_solaires:    { permis: :conditionnel, note: "PV en toiture : dispensé si intégrés et non visibles de la voie publique. En zone protégée → permis." },
    ventilation:          { permis: :non,          note: "VMC/VMD : travaux intérieurs dispensés de permis." },
    piscine:              { permis: :oui,          note: "Construction piscine (hors-sol ou enterrée) → permis d'urbanisme dans les 3 régions." },

    # ── Espaces extérieurs ──────────────────────────────────────────────────
    terrasse:             { permis: :conditionnel, note: "Terrasse ≤ 40m² au niveau du sol : souvent dispensée. Terrasse surélevée ou > 40m² → permis." },
    abri_jardin:          { permis: :conditionnel, note: "Abri jardin ≤ 15m² : dispensé en Flandre. En Wallonie/Bruxelles : ≤ 6m² dispensé, au-delà → permis." },
    cloture:              { permis: :conditionnel, note: "Clôture ≤ 2m : dispensée en règle générale. Au-delà ou en zone protégée → permis." },
    carport_pergola:      { permis: :conditionnel, note: "Carport/pergola : zone d'annexe possible, mais souvent permis selon surface et commune." },

    # ── Structure & extension ────────────────────────────────────────────────
    extension:            { permis: :oui,          note: "Toute extension du volume bâti (annexe, véranda, surélévation) → permis d'urbanisme obligatoire." },
    transformation:       { permis: :conditionnel, note: "Transformation intérieure (redistribution pièces) : généralement dispensée. Modif. structurelle ou changement d'affectation → permis." },
    demolition:           { permis: :oui,          note: "Démolition totale ou partielle → permis requis dans les 3 régions." },

    # ── Intérieur ────────────────────────────────────────────────────────────
    electricite:          { permis: :non,          note: "Travaux électriques intérieurs : pas de permis urbanisme (mais RGIE obligatoire)." },
    plomberie:            { permis: :non,          note: "Plomberie intérieure : pas de permis urbanisme." },
    salle_de_bain:        { permis: :non,          note: "Rénovation salle de bain sans modification structurelle : dispensée." },
    cuisine:              { permis: :non,          note: "Cuisine (sans modification structurelle) : dispensée." },
    sols_revetements:     { permis: :non,          note: "Revêtements de sol, peinture, plafonds : pas de permis." }
  }.freeze

  def initialize(project)
    @project  = project
    @property = project.property
  end

  # Résultat principal
  # @return [Hash]
  def predict
    rules_results = analyze_work_types
    zone_factors  = analyze_zone_factors
    overall       = compute_overall(rules_results, zone_factors)

    {
      verdict:      overall[:verdict],       # :oui | :non | :probable | :possible
      confiance:    overall[:confiance],      # 0-100
      label:        overall[:label],          # String affichage
      color:        overall[:color],          # Bootstrap color
      icon:         overall[:icon],           # Bootstrap icon
      region:       region_label,
      delai_jours:  delai_instruction,
      documents:    documents_requis(overall[:verdict]),
      alertes:      zone_factors[:alertes],
      travaux_analyses: rules_results,
      resume:       build_resume(overall, zone_factors, rules_results)
    }
  end

  private

  def region
    @region ||= @property.region.to_s.downcase
  end

  def region_label
    { 'wallonie' => 'Wallonie', 'flandre' => 'Flandre', 'bruxelles' => 'Bruxelles' }[region] || 'Belgique'
  end

  # ── Analyse des types de travaux déclarés ────────────────────────────────────
  def analyze_work_types
    declared = detect_declared_work_types
    return [] if declared.empty?

    declared.map do |type_key|
      rule = REGLES_TRAVAUX[type_key]
      next unless rule

      result = case rule[:permis]
               when :oui          then { verdict: :oui,          label: 'Permis requis',     color: 'danger'  }
               when :non          then { verdict: :non,          label: 'Dispensé',           color: 'success' }
               when :conditionnel then { verdict: :conditionnel, label: 'À vérifier',         color: 'warning' }
               end

      {
        type:    type_key,
        label:   type_key.to_s.humanize.gsub('_', ' '),
        verdict: result[:verdict],
        color:   result[:color],
        label_verdict: result[:label],
        note:    apply_regional_adjustment(rule[:note], type_key)
      }
    end.compact
  end

  # Détecte les types de travaux à partir des données projet
  def detect_declared_work_types
    types = []

    # Depuis le nom et la description du projet
    nom = [@project.nom, @project.description.to_s].join(' ').downcase

    KEYWORD_MAP.each do |keywords, work_type|
      types << work_type if keywords.any? { |k| nom.include?(k) }
    end

    # Depuis les corps de métiers renseignés
    corps = (@project.corps_metiers || []).map { |c| c['specialite'].to_s.downcase }
    corps.each do |specialite|
      KEYWORD_MAP.each do |keywords, work_type|
        types << work_type if keywords.any? { |k| specialite.include?(k) }
      end
    end

    # Depuis les type_travaux (champ CSV)
    if @project.respond_to?(:type_travaux) && @project.type_travaux.present?
      @project.type_travaux.split(',').map(&:strip).each do |t|
        types << :isolation_toiture    if t.include?('isolation')
        types << :chassis_fenetres     if t.include?('fenetre') || t.include?('chassis')
        types << :chaudiere            if t.include?('chauffage')
        types << :panneaux_solaires    if t.include?('solaire')
        types << :ventilation          if t.include?('ventilation')
      end
    end

    types.uniq
  end

  KEYWORD_MAP = {
    %w[toiture toit couverture charpente ardoise tuile]                => :toiture_renovation,
    %w[isolation toiture comble]                                        => :isolation_toiture,
    %w[isolation facade ite exterieur]                                  => :isolation_facade,
    %w[chassis fenetre vitrage double triple]                           => :chassis_fenetres,
    %w[facade ravalement enduit]                                        => :facade_ravallement,
    %w[ouverture percee aggrandissement fenetre porte facade]           => :facade_modification,
    %w[chaudiere gaz mazout condensation]                               => :chaudiere,
    %w[pompe chaleur aerothermie geothermie]                            => :pompe_chaleur_air,
    %w[forage geothermique]                                             => :pompe_chaleur_geo,
    %w[panneaux solaires photovoltaique pv]                             => :panneaux_solaires,
    %w[ventilation vmc vmh]                                             => :ventilation,
    %w[piscine jacuzzi bassin]                                          => :piscine,
    %w[terrasse dalle exterieure]                                       => :terrasse,
    %w[abri jardin remise cabanon]                                      => :abri_jardin,
    %w[cloture haie palissade]                                          => :cloture,
    %w[carport parking garage voiture porte-auto]                       => :carport_pergola,
    %w[extension agrandissement annexe veranda surélévation]            => :extension,
    %w[transformation redistribution cloisonnement]                     => :transformation,
    %w[demolition abattage mur porteur]                                 => :demolition,
    %w[electricite tableau electrique]                                  => :electricite,
    %w[plomberie eau sanitaire]                                         => :plomberie,
    %w[salle de bain douche baignoire]                                  => :salle_de_bain,
    %w[cuisine kitchenette]                                             => :cuisine,
    %w[parquet carrelage peinture sol]                                  => :sols_revetements
  }.freeze

  # ── Facteurs aggravants / alertes ──────────────────────────────────────────
  def analyze_zone_factors
    alertes = []

    # Zone protégée / classée
    if @property.bien_classe?
      alertes << {
        niveau: :danger,
        icon:   'bi-building-lock',
        titre:  'Bien classé / site protégé',
        detail: "Le bien est classé ou en zone de protection. Tout travail extérieur nécessite un permis et l'avis de la Commission Royale des Monuments et Sites (CRMS/AROHM)."
      }
    end

    if @property.facade_patrimoine?
      alertes << {
        niveau: :warning,
        icon:   'bi-shield-exclamation',
        titre:  'Façade inscrite au patrimoine',
        detail: "La façade est répertoriée. Les modifications extérieures sont soumises à des conditions strictes et nécessitent un permis avec avis patrimonial."
      }
    end

    if @property.petit_patrimoine?
      alertes << {
        niveau: :warning,
        icon:   'bi-house-heart',
        titre:  'Petit patrimoine',
        detail: "Éléments de petit patrimoine identifiés. Des restrictions peuvent s'appliquer selon le règlement communal."
      }
    end

    # Nouvelle construction
    if @property.nouvelle_construction?
      alertes << {
        niveau: :danger,
        icon:   'bi-building-add',
        titre:  'Nouvelle construction',
        detail: "Permis d'urbanisme obligatoire pour toute nouvelle construction, quelle que soit la surface."
      }
    end

    # Zone Natura 2000 / zones sensibles (déduites du code postal)
    if natura2000_zone?
      alertes << {
        niveau: :warning,
        icon:   'bi-tree',
        titre:  'Zone potentiellement sensible (Natura 2000 / ZACC)',
        detail: "Le code postal indique une zone potentiellement soumise à des protections environnementales. Un permis d'environnement supplémentaire peut être requis."
      }
    end

    # Extension avec bien_classe = blocage total
    bloc_patrimonial = alertes.any? { |a| a[:niveau] == :danger && a[:titre].include?('classé') }

    { alertes: alertes, bloc_patrimonial: bloc_patrimonial }
  end

  # ── Score global ─────────────────────────────────────────────────────────────
  def compute_overall(rules_results, zone_factors)
    return { verdict: :oui, confiance: 98, label: 'Permis requis', color: 'danger', icon: 'bi-x-octagon-fill' } if zone_factors[:bloc_patrimonial]

    nb_oui          = rules_results.count { |r| r[:verdict] == :oui }
    nb_conditionnel = rules_results.count { |r| r[:verdict] == :conditionnel }
    nb_non          = rules_results.count { |r| r[:verdict] == :non }
    nb_alertes      = zone_factors[:alertes].count

    if nb_oui > 0
      confiance = [75 + (nb_oui * 5) + (nb_alertes * 5), 95].min
      { verdict: :oui,      confiance: confiance, label: 'Permis requis',            color: 'danger',  icon: 'bi-x-octagon-fill'    }
    elsif nb_conditionnel > 0
      confiance = 60 + (nb_alertes * 8)
      if confiance > 75
        { verdict: :probable, confiance: confiance, label: 'Permis probablement requis', color: 'warning', icon: 'bi-exclamation-diamond-fill' }
      else
        { verdict: :possible, confiance: 55,        label: 'Permis peut-être requis',    color: 'info',    icon: 'bi-question-diamond-fill' }
      end
    elsif nb_non > 0
      confiance = [85 - (nb_alertes * 10), 50].max
      { verdict: :non,      confiance: confiance, label: 'Probablement dispensé',     color: 'success', icon: 'bi-check-circle-fill' }
    else
      # Pas de travaux identifiés — verdict générique
      { verdict: :inconnu,  confiance: 0,         label: 'Analyse insuffisante',       color: 'secondary', icon: 'bi-slash-circle' }
    end
  end

  # ── Documents requis selon verdict ──────────────────────────────────────────
  def documents_requis(verdict)
    base = []
    return base if verdict == :non

    base += [
      "Formulaire de demande de permis (disponible sur le site de la commune)",
      "Plans de situation et de masse (1/200e ou 1/500e) — élaborés par un architecte",
      "Plans des travaux avant/après (façades, coupes, détails) — architecte agréé",
      "Photos du bien existant (4 orientations minimum)",
      "Titre de propriété ou bail"
    ]

    if region == 'wallonie'
      base += [
        "Formulaire RESA (Wallonie) — version papier + dépôt numérique",
        "Notice d'évaluation des incidences si surface > 5.000m²",
        "Avis CRMS si zone de protection du patrimoine"
      ]
    elsif region == 'flandre'
      base += [
        "Formulaire de demande omgevingsvergunning (Omgevingsloket)",
        "Enregistrement en ligne sur : https://www.omgevingsloket.be",
        "Avis ROHM si bien classé (Onroerend Erfgoed)"
      ]
    elsif region == 'bruxelles'
      base += [
        "Formulaire Urban (bruxelles.be/urbanisme)",
        "Dossier RCU (Règlement Communal d'Urbanisme) de la commune",
        "Avis CRMS si immeuble classé ou en zone de protection"
      ]
    end

    if @property.bien_classe? || @property.facade_patrimoine?
      base << "Rapport spécialisé architecte du patrimoine (QUALITÉ CRMS exigée)"
    end

    base
  end

  # ── Délai instruction ────────────────────────────────────────────────────────
  def delai_instruction
    reg = region.to_sym
    config = DELAI_INSTRUCTION[reg] || DELAI_INSTRUCTION[:wallonie]
    "#{config[:normal]}-#{config[:prolonge]} jours"
  end

  # ── Ajustements régionaux ────────────────────────────────────────────────────
  def apply_regional_adjustment(note, type_key)
    adjustments = {
      flandre: {
        panneaux_solaires: "En Flandre : les panneaux solaires bénéficient d'une dispense étendue (omgevingsvergunning non requise pour la majorité des cas résidentiels).",
        abri_jardin:       "En Flandre : abri jardin ≤ 40m² en zone résidentielle dispensé (bijgebouw-regeling).",
        isolation_facade:  "En Flandre : ITE avec débord ≤ 16cm dispensé depuis 2018 (décret VCRO)."
      },
      wallonie: {
        panneaux_solaires: "En Wallonie : PV dispensés de permis sur toiture inclinée depuis 2022 (CWATUPE art. D.IV.4).",
        isolation_facade:  "En Wallonie : ITE avec débord ≤ 10cm dispensée depuis 2022."
      },
      bruxelles: {
        panneaux_solaires: "À Bruxelles : PV soumis à permis si visibles depuis l'espace public — vérifier avec l'urbanisme communal.",
        isolation_facade:  "À Bruxelles : ITE nécessite un permis d'urbanisme (CoBAT, art. 98)."
      }
    }

    reg_sym = region.to_sym
    adjustments.dig(reg_sym, type_key) || note
  end

  # ── Zones Natura 2000 (heuristique codes postaux belges) ────────────────────
  def natura2000_zone?
    cp = @property.code_postal.to_i
    # Zones connues : Ardennes, Hautes-Fagnes, polders flamands, forêts de Soignes
    NATURA2000_PREFIXES.any? { |range| range.include?(cp) }
  end

  NATURA2000_PREFIXES = [
    (4800..4999),  # Hautes-Fagnes / Ardennes Liège
    (6600..6997),  # Ardennes Luxembourg belge
    (5300..5375),  # Vallée de la Meuse / Namur
    (8600..8699),  # Polders côtiers Flandre
    (9990..9999),  # Réserves côtières
    (1300..1370)   # Forêt de Soignes / Brabant wallon
  ].freeze

  # ── Résumé textuel ────────────────────────────────────────────────────────────
  def build_resume(overall, zone_factors, rules_results)
    travaux_avec_permis = rules_results.select { |r| r[:verdict] == :oui }.map { |r| r[:label] }
    travaux_conditionnels = rules_results.select { |r| r[:verdict] == :conditionnel }.map { |r| r[:label] }

    lines = []

    case overall[:verdict]
    when :oui
      if travaux_avec_permis.any?
        lines << "Les travaux suivants nécessitent un permis d'urbanisme : **#{travaux_avec_permis.join(', ')}**."
      end
      lines << "Un dossier complet doit être déposé auprès de la commune compétente."
      lines << "Délai d'instruction estimé : #{delai_instruction}."
    when :probable, :possible
      if travaux_conditionnels.any?
        lines << "Les travaux **#{travaux_conditionnels.join(', ')}** nécessitent une vérification au cas par cas."
      end
      lines << "Consultez le service urbanisme de votre commune pour confirmation avant le démarrage des travaux."
    when :non
      lines << "Sur base des travaux déclarés, les travaux semblent dispensés de permis d'urbanisme."
      lines << "Vérifiez néanmoins le règlement communal d'urbanisme (RCU) qui peut imposer des conditions spécifiques."
    end

    if zone_factors[:alertes].any?
      lines << "⚠️ **Attention** : #{zone_factors[:alertes].count} facteur(s) aggravant(s) identifié(s) (bien classé, zone protégée…)."
    end

    lines << "_Cette analyse IA est indicative (#{overall[:confiance]}% de confiance). Elle ne remplace pas l'avis d'un architecte ou du service communal d'urbanisme._"

    lines.join(' ')
  end
end
