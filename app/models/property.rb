class Property < ApplicationRecord
  self.inheritance_column = nil  # Désactiver l'héritage STI pour la colonne 'type'

  attr_accessor :skip_onboarding_validation

  serialize :elements_petit_patrimoine, coder: JSON

  belongs_to :user
  has_many :simulations, dependent: :destroy
  has_many :peb_donnees, dependent: :destroy
  has_many :audit_energ_donnees, dependent: :destroy
  has_many :projects, dependent: :destroy
  has_many :requests, dependent: :destroy
  has_many :tenants, dependent: :destroy
  has_many :leases, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :quotes, dependent: :destroy

  # Active Storage pour les images
  has_one_attached :photo

  # Relations pour les phases de documents
  has_many :document_phase_statuses, dependent: :destroy
  has_many :document_phases, through: :document_phase_statuses

  # Géocodage
  geocoded_by :full_address
  after_validation :geocode, if: ->(obj){ obj.full_address.present? && (obj.rue_changed? || obj.numero_changed? || obj.code_postal_changed? || obj.commune_changed?) }

  # Statuts de vente
  enum :statut_vente, { actif: 'actif', en_vente: 'en_vente', vendu: 'vendu' }, prefix: false

  # Callback pour normaliser la région
  before_save :normalize_region

  # Callback pour initialiser les phases de documents
  after_create :initialize_document_phases

  # Callback pour initialiser les phases sur les propriétés existantes si nécessaire
  after_find :ensure_document_phases_exist

  # Validations pour les champs obligatoires essentiels
  validates :rue, :numero, :code_postal, :commune, :region, presence: true

  # Validations régionales conditionnelles - temporairement assouplies pour debugging
  validates :type_bien_flandre, presence: true, if: -> { region == 'flandre' && new_record? && !skip_onboarding_validation }
  validates :usage_flandre, presence: true, if: -> { region == 'flandre' && new_record? && !skip_onboarding_validation }
  # validates :ean_flandre, presence: true, if: -> { region == 'flandre' } # Temporairement désactivé
  validates :type_propriete_wallonie, presence: true, if: -> { region == 'wallonie' && new_record? && !skip_onboarding_validation }
  validates :type_bien_bruxelles, presence: true, if: -> { region == 'bruxelles' && new_record? && !skip_onboarding_validation }

  # Validations optionnelles - à réactiver plus tard selon les besoins
  # validates :type, :occupation, presence: true
  # validates :annee_construction, :date_raccordement_electrique, :numero_ean, presence: true, if: :strict_validation_required?

  # Validations pour les champs radio - temporairement désactivées
  # validates :autre_bien, inclusion: { in: %w[oui non] }, allow_blank: true
  # validates :peb, inclusion: { in: %w[ef autre] }, allow_blank: true
  # validates :reconstruit, inclusion: { in: %w[oui non] }, allow_blank: true

  # Méthode pour l'adresse complète
  def full_address
    "#{numero} #{rue}, #{code_postal} #{commune}"
  end

  # Méthode pour compatibilité avec les vues existantes
  def address
    full_address
  end

  def location
    full_address
  end

  # Méthodes pour la géolocalisation
  def geocoded?
    latitude.present? && longitude.present?
  end

  def coordinates
    [latitude, longitude] if geocoded?
  end

  def map_popup_content
    {
      name: name,
      address: full_address,
      price: valeur_achat,
      peb_value: peb_certificate_value,
      user_email: user&.email
    }
  end

  def peb_certificate_value
    case region&.downcase
    when 'wallonie'
      certificat_peb_wallonie
    when 'flandre'
      certificat_peb_flandre
    when 'bruxelles'
      certificat_peb_bruxelles
    else
      peb
    end
  end

  # Méthodes pour les dashboards et le suivi de complétude

  # Retourne une analyse détaillée champ par champ de la complétude des données
  def data_completeness_details
    labels = {
      titre: "Nom du bien",
      rue: "Rue", numero: "Numéro", code_postal: "Code postal",
      commune: "Commune", region: "Région",
      type_propriete_wallonie: "Type de propriété (Wallonie)",
      type_bien_wallonie: "Type de bien (Wallonie)",
      profil_demandeur: "Profil demandeur",
      certificat_peb_wallonie: "Certificat PEB (Wallonie)",
      occupation: "Type d'occupation",
      surface_habitable_wallonie: "Surface habitable (m²)",
      mode_chauffage_wallonie: "Mode de chauffage",
      annee_construction: "Année de construction",
      type_bien_flandre: "Type de bien (Flandre)",
      usage_flandre: "Usage (Flandre)",
      certificat_peb_flandre: "Certificat PEB (Flandre)",
      surface_habitable: "Surface habitable (m²)",
      chauffage_post_renovation_flandre: "Chauffage post-rénovation",
      ean_flandre: "Numéro EAN (Flandre)",
      type_bien_bruxelles: "Type de bien (Bruxelles)",
      certificat_peb_bruxelles: "Certificat PEB (Bruxelles)",
      surface_totale: "Surface totale (m²)",
      numero_cadastre: "Numéro cadastral",
      valeur_achat: "Valeur d'achat",
      date_achat: "Date d'achat"
    }

    identite = {
      label: "Identité du bien",
      fields: build_field_details([:titre, :rue, :numero, :code_postal, :commune, :region, :numero_cadastre], labels)
    }

    admin = {
      label: "Informations administratives",
      fields: build_field_details(admin_fields_for_region - [:rue, :numero, :code_postal, :commune, :region], labels)
    }

    technique = {
      label: "Caractéristiques techniques",
      fields: build_field_details(chantier_fields_for_region, labels)
    }

    investissement = {
      label: "Valeur & investissement",
      fields: build_field_details([:valeur_achat, :date_achat], labels)
    }

    categories = [identite, admin, technique, investissement].map do |cat|
      total = cat[:fields].count
      done = cat[:fields].count { |f| f[:filled] }
      cat.merge(total: total, done: done, percentage: total.zero? ? 0 : (done.to_f / total * 100).round)
    end

    all_fields = categories.flat_map { |c| c[:fields] }
    global_total = all_fields.count
    global_done = all_fields.count { |f| f[:filled] }

    {
      categories: categories,
      total: global_total,
      done: global_done,
      percentage: global_total.zero? ? 0 : (global_done.to_f / global_total * 100).round,
      missing: all_fields.reject { |f| f[:filled] }.map { |f| f[:label] }
    }
  end

  def completion_percentage
    # Calcul de complétude incluant les documents
    admin_weight = 0.3
    chantier_weight = 0.3
    primes_weight = 0.2
    documents_weight = 0.2

    overall = (admin_completion_percentage * admin_weight +
               chantier_completion_percentage * chantier_weight +
               primes_completion_percentage * primes_weight +
               documents_completion_percentage * documents_weight)

    overall.round
  end

  def admin_completion_percentage
    admin_fields = admin_fields_for_region
    total = admin_fields.count
    completed = admin_fields.count { |field| self[field].present? }
    return 0 if total.zero?
    (completed.to_f / total * 100).round
  end

  def chantier_completion_percentage
    chantier_fields = chantier_fields_for_region
    total = chantier_fields.count
    completed = chantier_fields.count { |field| self[field].present? }
    return 0 if total.zero?
    (completed.to_f / total * 100).round
  end

  def primes_completion_percentage
    # Pour l'instant, on se base sur la présence d'au moins une simulation
    simulations.any? ? 100 : 0
  end

  # Méthode pour identifier les biens d'entreprises
  def is_entreprise?
    # Une propriété est considérée comme entreprise si :
    # 1. Elle a le type "entreprise" dans la propriété elle-même, OU
    # 2. Elle a des simulations avec category = 'entreprise'
    type == 'entreprise' ||
    simulations.where(category: 'entreprise').exists?
  end

  def ready_for_request?
    completion_percentage >= 80
  end

  def completion_status
    percentage = completion_percentage
    case percentage
    when 0...30 then 'danger'
    when 30...70 then 'warning'
    when 70...90 then 'info'
    else 'success'
    end
  end

  def admin_completion_class
    case admin_completion_percentage
    when 0...50 then 'bg-danger'
    when 50...80 then 'bg-warning'
    else 'bg-success'
    end
  end

  def chantier_completion_class
    case chantier_completion_percentage
    when 0...50 then 'bg-danger'
    when 50...80 then 'bg-warning'
    else 'bg-success'
    end
  end

  def primes_completion_class
    primes_completion_percentage > 0 ? 'bg-success' : 'bg-secondary'
  end

  def name
    # Génère un nom basé sur le type et la localisation selon la région
    begin
      type_display = case region&.downcase
                     when 'wallonie'
                       type_propriete_wallonie&.humanize || 'Bien'
                     when 'flandre'
                       type_bien_flandre&.humanize || 'Bien'
                     when 'bruxelles'
                       type_bien_bruxelles&.humanize || 'Bien'
                     else
                       type&.humanize || 'Bien'
                     end
      location_name = commune.present? ? commune : 'Sans adresse'
      "#{type_display} #{location_name}"
    rescue => e
      Rails.logger.error "Property#name error for property #{id}: #{e.message}"
      "Bien #{commune || id}"
    end
  end

  def missing_required_fields
    required_fields.select { |field| self[field].blank? }
  end

  # ─── Vente ────────────────────────────────────────────────────────────────

  # Documents légaux incontournables pour une vente (selon droit belge)
  DOCS_VENTE_OBLIGATOIRES = {
    'certificat_peb'           => 'Certificat PEB (obligatoire lors de la vente)',
    'attestation_conformite'   => 'Attestation de conformité électrique',
    'permis_urbanisme'         => 'Permis d\'urbanisme des travaux réalisés',
    'acte_notarial'            => 'Acte notarial / titre de propriété'
  }.freeze

  # Documents DIU à transmettre à l'acheteur
  DOCS_DIU_TRANSMISSION = {
    'plan_diu'                 => 'Plans des travaux (DIU)',
    'fiche_technique'          => 'Fiches techniques matériaux',
    'notice_equipement'        => 'Notices d\'équipements',
    'fiche_securite_materiaux' => 'Fiches de sécurité matériaux',
    'certificat_garantie'      => 'Certificats de garantie',
    'instruction_entretien'    => 'Instructions d\'entretien',
    'assurance_decennale'      => 'Assurances décennales entrepreneurs',
    'facture'                  => 'Factures des travaux réalisés'
  }.freeze

  def statut_vente_label
    case statut_vente
    when 'en_vente' then 'En vente'
    when 'vendu'    then 'Vendu'
    else 'Actif'
    end
  end

  def statut_vente_badge_class
    case statut_vente
    when 'en_vente' then 'bg-warning text-dark'
    when 'vendu'    then 'bg-success'
    else 'bg-secondary'
    end
  end

  # Vérifie la présence des documents légaux obligatoires pour la vente
  def checklist_vente
    all_docs = documents.pluck(:type_document).uniq
    # Aussi chercher dans les projets liés
    project_docs = Document.where(project_id: projects.pluck(:id)).pluck(:type_document).uniq
    present_types = (all_docs + project_docs).uniq

    DOCS_VENTE_OBLIGATOIRES.map do |type, label|
      present = present_types.include?(type) ||
                (type == 'certificat_peb' && peb_certificate_value.present?)
      { type: type, label: label, present: present }
    end
  end

  # Vérifie la présence des documents DIU à transmettre
  def checklist_diu
    project_docs = Document.where(project_id: projects.pluck(:id)).pluck(:type_document)
    property_docs = documents.pluck(:type_document)
    present_types = (project_docs + property_docs).uniq

    DOCS_DIU_TRANSMISSION.map do |type, label|
      { type: type, label: label, present: present_types.include?(type) }
    end
  end

  def vente_readiness_score
    items = checklist_vente + checklist_diu
    return 0 if items.empty?
    (items.count { |i| i[:present] }.to_f / items.size * 100).round
  end

  # Méthode de debug pour voir quels champs sont évalués
  def completion_debug_info
    {
      region: region,
      admin_fields: admin_fields_for_region,
      admin_completed: admin_fields_for_region.select { |field| self[field].present? },
      admin_missing: admin_fields_for_region.select { |field| self[field].blank? },
      chantier_fields: chantier_fields_for_region,
      chantier_completed: chantier_fields_for_region.select { |field| self[field].present? },
      chantier_missing: chantier_fields_for_region.select { |field| self[field].blank? }
    }
  end

  # Méthodes pour les documents
  def documents_completion_percentage
    stats = Document.completion_stats_for_property(self)
    stats[:percentage]
  end

  def documents_completion_class
    case documents_completion_percentage
    when 0...50 then 'bg-danger'
    when 50...80 then 'bg-warning'
    else 'bg-success'
    end
  end

  def completed_documents_count
    stats = Document.completion_stats_for_property(self)
    stats[:completed]
  end

  def total_required_documents
    stats = Document.completion_stats_for_property(self)
    stats[:total]
  end

  def documents_by_type
    documents.group_by(&:type_document)
  end

  # Méthodes pour le formulaire miroir
  def ready_for_submission?
    admin_completion_percentage >= 80 &&
    chantier_completion_percentage >= 60 &&
    documents_completion_percentage >= 80
  end

  def missing_for_submission
    missing = []
    missing << "Informations administratives incomplètes" if admin_completion_percentage < 80
    missing << "Informations chantier incomplètes" if chantier_completion_percentage < 60
    missing << "Documents manquants" if documents_completion_percentage < 80
    missing
  end

  def has_travaux?(type)
    # À adapter selon votre logique de travaux
    # Pour l'instant, retourne false - à implémenter avec vos données
    false
  end

  def submission_readiness_class
    if ready_for_submission?
      'bg-success'
    elsif completion_percentage >= 50
      'bg-warning'
    else
      'bg-danger'
    end
  end

  # === MÉTHODES POUR LES PHASES DE DOCUMENTS ===

  # Récupère ou crée le statut d'une phase pour cette propriété
  def phase_status_for(document_phase)
    document_phase_statuses.find_or_create_by(document_phase: document_phase) do |status|
      status.refresh_status!
    end
  end

  # Calcule le pourcentage de complétude global par phases
  def phases_completion_percentage
    statuses = document_phase_statuses.includes(:document_phase)
    return 0 if statuses.empty?

    total_percentage = statuses.sum(&:completion_percentage)
    (total_percentage.to_f / statuses.count).round
  end

  # Récupère toutes les phases avec leurs statuts pour cette propriété
  def phases_with_status
    phases_scope = determine_phase_category == 'investissement' ?
                     DocumentPhase.investissement.ordered :
                     DocumentPhase.chantier.ordered

    phases_scope.includes(:document_phase_statuses).map do |phase|
      {
        phase: phase,
        status: phase_status_for(phase),
        completion_percentage: phase.completion_percentage_for_property(self),
        phase_status: phase.status_for_property(self),
        missing_required: phase.missing_required_documents_for_property(self),
        missing_optional: phase.missing_optional_documents_for_property(self)
      }
    end
  end

  # Détermine si cette propriété utilise les phases chantier ou investissement
  def determine_phase_category
    # Si c'est une entreprise avec des projets économiques, on utilise les phases investissement
    if is_entreprise? && projects.where(finalite: 'economique').exists?
      'investissement'
    else
      'chantier'
    end
  end

  # Phases en cours ou bloquées nécessitant attention
  def phases_needing_attention
    phases_with_status.select do |phase_data|
      ['not_started', 'blocked', 'started'].include?(phase_data[:phase_status])
    end
  end

  # Prochaine phase à compléter
  def next_phase_to_complete
    phases_needing_attention.first
  end

  # Documents manquants critiques pour toutes les phases
  def critical_missing_documents
    DocumentPhase.ordered.flat_map do |phase|
      phase.missing_required_documents_for_property(self)
    end.uniq
  end

  # Obtient les actions recommandées pour les phases
  def recommended_phase_actions
    actions = []

    phases_with_status.each do |phase_data|
      phase = phase_data[:phase]
      status = phase_data[:status]

      phase_actions = status.next_recommended_actions
      phase_actions.each do |action|
        actions << action.merge(phase: phase.name, phase_id: phase.id)
      end
    end

    # Trier par priorité (high, medium, low)
    priority_order = { 'high' => 1, 'medium' => 2, 'low' => 3 }
    actions.sort_by { |action| priority_order[action[:priority]] || 4 }
  end

  # Met à jour les statuts de toutes les phases
  def refresh_all_phase_statuses!
    DocumentPhase.ordered.each do |phase|
      phase_status_for(phase).refresh_status!
    end
  end

  # Vérifie si toutes les phases sont complètes
  def all_phases_complete?
    phases_with_status.all? { |data| ['complete', 'nearly_complete'].include?(data[:phase_status]) }
  end

  # Temps estimé pour compléter toutes les phases restantes
  def estimated_completion_time_all_phases
    incomplete_phases = phases_with_status.reject { |data| data[:phase_status] == 'complete' }

    case incomplete_phases.count
    when 0
      'Terminé'
    when 1
      incomplete_phases.first[:status].estimated_completion_time
    when 2..3
      '1-2 semaines'
    else
      '3-4 semaines'
    end
  end

  def admin_fields_for_region
    # Champs de base communs à toutes les régions
    fields = [:rue, :numero, :code_postal, :commune, :region]

    # Ajout des champs régionaux selon la région
    case region&.downcase
    when 'wallonie'
      fields += [:type_propriete_wallonie, :type_bien_wallonie, :profil_demandeur, :certificat_peb_wallonie]
    when 'flandre'
      fields += [:type_bien_flandre, :usage_flandre, :certificat_peb_flandre]
    when 'bruxelles'
      fields += [:type_bien_bruxelles, :certificat_peb_bruxelles, :profil_demandeur]
    else
      # Fallback vers l'ancien champ générique si pas de région définie
      fields += [:type] if respond_to?(:type)
    end

    fields
  end

  def chantier_fields_for_region
    # Champs de base communs à toutes les régions
    fields = [:annee_construction]

    # Ajout des champs régionaux spécifiques selon la région
    case region&.downcase
    when 'wallonie'
      # Pour la Wallonie : surface habitable, mode de chauffage et occupation
      fields += [:surface_habitable_wallonie, :mode_chauffage_wallonie, :occupation]
    when 'flandre'
      # Pour la Flandre : surface habitable, système chauffage et EAN
      fields += [:surface_habitable, :chauffage_post_renovation_flandre, :ean_flandre]
    when 'bruxelles'
      # Pour Bruxelles : surface habitable et champs spécifiques
      fields += [:surface_habitable, :usage, :occupation, :surface_totale]
    else
      # Fallback vers les anciens champs génériques si pas de région définie
      fields += [:surface_habitable, :date_raccordement_electrique, :numero_ean, :autre_bien, :peb]
    end

    fields
  end

  private

  # Callback pour initialiser les phases de documents après création
  def initialize_document_phases
    # S'assurer que les phases par défaut existent
    DocumentPhase.create_default_phases!

    # Créer les statuts pour toutes les phases
    DocumentPhase.ordered.each do |phase|
      phase_status_for(phase)
    end
  end

  # S'assurer que les phases existent pour les propriétés existantes
  def ensure_document_phases_exist
    return if new_record? || document_phase_statuses.any?

    # Initialiser les phases si elles n'existent pas
    begin
      initialize_document_phases
    rescue => e
      Rails.logger.warn "Erreur lors de l'initialisation des phases pour la propriété #{id}: #{e.message}"
    end
  end

  def required_fields
    # Champs minimum requis pour l'enregistrement
    fields = [:rue, :numero, :code_postal, :commune, :region]

    # Ajout des champs régionaux requis selon la région
    # Exclure type_bien_bruxelles pour les entreprises car incompatible avec éligibilité Renolution
    case region&.downcase
    when 'wallonie'
      fields += [:type_propriete_wallonie]
    when 'flandre'
      fields += [:type_bien_flandre]
    when 'bruxelles'
      # Pour les entreprises, ne pas exiger type_bien_bruxelles
      fields += [:type_bien_bruxelles] unless is_entreprise?
    end

    fields
  end

  def strict_validation_required?
    # Pour l'instant, on désactive les validations strictes pour permettre la création
    # Elles peuvent être activées plus tard selon la logique métier
    false
  end

  private

  def build_field_details(fields, labels)
    fields.uniq.map do |field|
      value = self[field]
      { field: field, label: labels[field] || field.to_s.humanize, filled: value.present?, value: value }
    end
  end

  def normalize_region
    self.region = region&.downcase if region.present?
  end
end
