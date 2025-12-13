class Request < ApplicationRecord
  belongs_to :user
  belongs_to :property, optional: true
  belongs_to :project, optional: true
  belongs_to :simulation, optional: true

  has_many :request_progresses
  has_many :documents

  # Support pour les fichiers Flandre
  has_many_attached :document_devis
  has_many_attached :document_factures
  has_many_attached :document_aer
  has_many_attached :document_peb
  has_many_attached :document_attestations
  has_many_attached :document_photos
  has_many_attached :document_autres

  validates :status, presence: true
  validates :title, presence: true, unless: -> { draft? || autosave_mode? }
  validates :description, presence: true, unless: -> { draft? || autosave_mode? }
  validates :region, presence: true, unless: -> { draft? || autosave_mode? }
  validates :form_type, presence: true, unless: -> { draft? || autosave_mode? }

  # Enum pour les types de formulaires (25 formulaires)
  enum :form_type, {
    # BRUXELLES (4 formulaires)
    regional_bruxelles: 'regional_bruxelles',
    monuments_bruxelles: 'monuments_bruxelles',
    patrimoine_bruxelles: 'patrimoine_bruxelles',
    communal_bruxelles: 'communal_bruxelles',

    # WALLONIE (4 formulaires)
    regional_wallonie: 'regional_wallonie',
    audit_wallonie: 'audit_wallonie',
    monuments_wallonie: 'monuments_wallonie',
    communal_wallonie: 'communal_wallonie',

    # FLANDRE (3 formulaires)
    regional_flandre: 'regional_flandre',
    monuments_flandre: 'monuments_flandre',
    communal_flandre: 'communal_flandre',

    # ENTREPRISES (14 formulaires - complets pour Bruxelles)
    consultance_bruxelles: 'consultance_bruxelles',
    investissement_bruxelles: 'investissement_bruxelles',
    formation_bruxelles: 'formation_bruxelles',
    recherche_bruxelles: 'recherche_bruxelles',
    export_bruxelles: 'export_bruxelles',
    innovation_bruxelles: 'innovation_bruxelles',
    transition_bruxelles: 'transition_bruxelles',
    accessibilite_bruxelles: 'accessibilite_bruxelles',
    achat_immobilier_bruxelles: 'achat_immobilier_bruxelles',
    conformite_normes_bruxelles: 'conformite_normes_bruxelles',
    digitalisation_bruxelles: 'digitalisation_bruxelles',
    formation_linguistique_bruxelles: 'formation_linguistique_bruxelles',
    mobilite_retrofit_bruxelles: 'mobilite_retrofit_bruxelles',
    recrutement_bruxelles: 'recrutement_bruxelles',
    consultance_wallonie: 'consultance_wallonie',
    investissement_wallonie: 'investissement_wallonie',
    consultance_flandre: 'consultance_flandre',
    investissement_flandre: 'investissement_flandre',
    formation_flandre: 'formation_flandre',
    innovation_flandre: 'innovation_flandre',
    transition_flandre: 'transition_flandre'
  }

  # Validations spécifiques pour Flandre (uniquement si pas brouillon)
  validates :domicile, inclusion: { in: [true, false] }, if: -> { flandre? && !draft? && !autosave_mode? }
  validates :type_demandeur, presence: true, if: -> { flandre? && !draft? && !autosave_mode? }
  validates :registre_national, presence: true, if: -> { flandre? && !draft? && !autosave_mode? }
  validates :nom, presence: true, if: -> { flandre? && !draft? && !autosave_mode? }
  validates :prenom, presence: true, if: -> { flandre? && !draft? && !autosave_mode? }
  validates :telephone, presence: true, if: -> { flandre? && !draft? && !autosave_mode? }
  validates :email, presence: true, if: -> { flandre? && !draft? && !autosave_mode? }
  validates :adresse, presence: true, if: -> { flandre? && !draft? && !autosave_mode? }
  validates :code_postal, presence: true, if: -> { flandre? && !draft? && !autosave_mode? }
  validates :commune, presence: true, if: -> { flandre? && !draft? && !autosave_mode? }
  validates :type_bien, presence: true, if: -> { flandre? && !draft? && !autosave_mode? }
  validates :usage, presence: true, if: -> { flandre? && !draft? && !autosave_mode? }
  validates :chauffage_post_renovation, presence: true, if: -> { flandre? && !draft? && !autosave_mode? }
  validates :revenus_annuels, presence: true, numericality: { greater_than: 0 }, if: -> { flandre? && !draft? && !autosave_mode? }
  validates :personnes_charge, presence: true, numericality: { greater_than_or_equal_to: 0 }, if: -> { flandre? && !draft? && !autosave_mode? }
  validates :annee_aer, presence: true, if: -> { flandre? && !draft? && !autosave_mode? }
  validates :email_contact, presence: true, if: -> { flandre? && !draft? && !autosave_mode? }
  validates :confirmation_veracite, acceptance: true, if: -> { flandre? && !draft? && !autosave_mode? }
  validates :acceptation_conditions, acceptance: true, if: -> { flandre? && !draft? && !autosave_mode? }

  # Documents obligatoires pour Flandre - validations personnalisées (uniquement si pas brouillon)
  validate :document_devis_must_be_attached, if: -> { flandre? && !draft? && !autosave_mode? }
  validate :document_factures_must_be_attached, if: -> { flandre? && !draft? && !autosave_mode? }
  validate :document_aer_must_be_attached, if: -> { flandre? && !draft? && !autosave_mode? }

  # Scope pour récupérer les demandes récentes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_form_type, ->(type) { where(form_type: type) }
  scope :for_property, ->(property) { where(property: property) }

  # Attribut pour désactiver les validations pendant l'auto-save
  attr_accessor :autosave_mode

  # Méthodes publiques pour vérifier les permissions
  def can_be_deleted?
    status == 'draft'
  end

  def can_be_edited?
    ['draft', 'pending'].include?(status)
  end

  def flandre?
    region == 'flandre'
  end

  def draft?
    status == 'draft'
  end

  def autosave_mode?
    @autosave_mode == true
  end

  # Méthodes pour les nouveaux types de formulaires
  def form_region
    return 'entreprise' if entreprise_form?
    form_type&.split('_')&.last
  end

  def entreprise_form?
    form_type&.include?('consultance') || form_type&.include?('investissement') ||
    form_type&.include?('formation') || form_type&.include?('recherche') ||
    form_type&.include?('export') || form_type&.include?('innovation') ||
    form_type&.include?('transition')
  end

  def regional_form?
    form_type&.start_with?('regional_')
  end

  def monuments_form?
    form_type&.start_with?('monuments_')
  end

  def patrimoine_form?
    form_type&.start_with?('patrimoine_')
  end

  def communal_form?
    form_type&.start_with?('communal_')
  end

  def audit_form?
    form_type&.start_with?('audit_')
  end

  # Gestion des form_data
  def form_data_value(key)
    form_data[key.to_s]
  end

  def set_form_data(key, value)
    self.form_data = form_data.merge(key.to_s => value)
  end

  def form_completion_percentage
    return 0 if form_type.blank?

    required_fields = get_required_fields_for_form_type
    return 100 if required_fields.empty?

    completed_fields = required_fields.count { |field| form_data_value(field).present? }
    (completed_fields.to_f / required_fields.size * 100).round
  end

  def ready_for_submission?
    form_completion_percentage >= 80 && valid?
  end

  private

  def get_required_fields_for_form_type
    # Configuration des champs requis selon le type de formulaire
    case form_type
    when 'regional_bruxelles', 'regional_wallonie', 'regional_flandre'
      %w[nom prenom email telephone adresse travaux_description budget_estime]
    when 'monuments_bruxelles', 'monuments_wallonie', 'monuments_flandre'
      %w[nom prenom email telephone adresse bien_classe description_travaux]
    when 'patrimoine_bruxelles'
      %w[nom prenom email telephone adresse elements_patrimoine]
    when 'audit_wallonie'
      %w[nom prenom email telephone adresse type_audit]
    when /consultance_/
      %w[denomination numero_entreprise contact_nom contact_email projet_description]
    when /investissement_/
      %w[denomination numero_entreprise investissement_description montant_investissement]
    else
      []
    end
  end

  public

  def tracking_email
    return nil unless persisted? && region.present?

    timestamp = id || Time.current.to_i
    prop_id = property&.id || 'general'
    proj_id = project&.id || 'general'
    region_code = region.downcase

    "#{region_code}-#{prop_id}-#{proj_id}-#{timestamp}@tracking.ren0vate.be"
  end

  def update_contractor_status!
    if all_contractors_signed?
      # Logique pour passer à l'étape suivante
      Rails.logger.info "Request #{id}: Toutes les signatures entrepreneurs collectées"
    end
  end

  private

  def document_devis_must_be_attached
    errors.add(:document_devis, "doit être joint") unless document_devis.attached?
  end

  def document_factures_must_be_attached
    errors.add(:document_factures, "doit être joint") unless document_factures.attached?
  end

  def document_aer_must_be_attached
    errors.add(:document_aer, "doit être joint") unless document_aer.attached?
  end
end
