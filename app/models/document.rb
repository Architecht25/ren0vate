class Document < ApplicationRecord
  belongs_to :user
  belongs_to :property, optional: true
  belongs_to :request, optional: true
  belongs_to :project, optional: true
  belongs_to :simulation, optional: true

  has_one_attached :file

  # Validations améliorées pour l'upload
  validates :type_document, presence: true
  validates :file_url, presence: true, unless: -> { file.attached? }
  validate :file_or_url_present
  validate :file_size_limit
  validate :file_format_validation

  # Énumérations pour les types de documents
  enum :type_document, {
    facture: 'facture',
    devis: 'devis',
    etat_avancement: 'etat_avancement',
    attestation_entrepreneur: 'attestation_entrepreneur',
    certificat_peb: 'certificat_peb',
    photo: 'photo',
    certificat_label: 'certificat_label',
    attestation_conformite: 'attestation_conformite',
    plan: 'plan',
    permis_urbanisme: 'permis_urbanisme',
    dossier_prime: 'dossier_prime',
    certificat_protection: 'certificat_protection'
  }

  # Status est une colonne string dans la DB, pas un enum integer
  enum :status, { pending: 'pending', approved: 'approved', rejected: 'rejected' }

  scope :for_property, ->(property) { where(property: property) }
  scope :by_type, ->(type) { where(type_document: type) }
  scope :completed, -> { where(status: :approved) }
  scope :by_phase, ->(phase) { where(type_document: phase.required_document_types + phase.optional_document_types) }

  # Callbacks pour maintenir les statuts des phases à jour
  after_save :refresh_property_phase_statuses
  after_destroy :refresh_property_phase_statuses

  # Formats de fichiers autorisés
  ALLOWED_FORMATS = {
    images: %w[image/jpeg image/png image/gif image/webp],
    documents: %w[application/pdf application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document],
    spreadsheets: %w[application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet]
  }.freeze

  ALL_ALLOWED_FORMATS = ALLOWED_FORMATS.values.flatten.freeze

  # Limite de taille (10 MB)
  MAX_FILE_SIZE = 10.megabytes

  # Méthodes helper
  def completed?
    approved?
  end

  def file_name
    file.attached? ? file.filename.to_s : File.basename(file_url.to_s) if file_url.present?
  end

  def file_size_human
    file.attached? ? ActionController::Base.helpers.number_to_human_size(file.byte_size) : nil
  end

  def file_type
    if file.attached?
      file.content_type
    elsif file_url.present?
      File.extname(file_url).downcase
    end
  end

  def is_image?
    return false unless file.attached?
    ALLOWED_FORMATS[:images].include?(file.content_type)
  end

  def is_pdf?
    return false unless file.attached?
    file.content_type == 'application/pdf'
  end

  def preview_available?
    is_image? || is_pdf?
  end

  def self.completion_stats_for_property(property)
    total_types = type_documents.values.count
    completed_types = for_property(property).completed.distinct.count(:type_document)
    {
      total: total_types,
      completed: completed_types,
      percentage: total_types > 0 ? (completed_types * 100.0 / total_types).round : 0
    }
  end

  # === MÉTHODES POUR LES PHASES ===

  # Trouve la phase associée à ce document
  def document_phase
    return nil unless type_document.present?
    DocumentPhase.find_phase_for_document_type(type_document)
  end

  # Vérifie si ce document est requis pour sa phase
  def required_for_phase?
    phase = document_phase
    return false unless phase
    phase.required_document_types.include?(type_document)
  end

  # Vérifie si ce document est optionnel pour sa phase
  def optional_for_phase?
    phase = document_phase
    return false unless phase
    phase.optional_document_types.include?(type_document)
  end

  # Badge de priorité basé sur la phase
  def priority_badge_class
    if required_for_phase?
      'danger'
    elsif optional_for_phase?
      'warning'
    else
      'secondary'
    end
  end

  # Texte de priorité
  def priority_text
    if required_for_phase?
      'Obligatoire'
    elsif optional_for_phase?
      'Optionnel'
    else
      'Non classé'
    end
  end

  # Impact sur l'avancement de la phase
  def phase_impact_percentage
    return 0 unless property && document_phase

    # Calcul de l'impact de ce document sur la phase
    if required_for_phase?
      required_count = document_phase.required_document_types.count
      return required_count > 0 ? (70.0 / required_count) : 0
    elsif optional_for_phase?
      optional_count = document_phase.optional_document_types.count
      return optional_count > 0 ? (30.0 / optional_count) : 0
    end

    0
  end

  # Suggestions d'amélioration pour ce document
  def improvement_suggestions
    suggestions = []

    case status
    when 'pending'
      if created_at < 3.days.ago
        days_ago = (Date.current - created_at.to_date).to_i
        suggestions << "Document en attente depuis #{days_ago} jour(s). Relancer si nécessaire."
      end
    when 'rejected'
      suggestions << "Document rejeté. Vérifier les critères requis et re-soumettre."
    when 'approved'
      if required_for_phase? && document_phase
        missing_siblings = document_phase.missing_required_documents_for_property(property)
        if missing_siblings.any?
          suggestions << "Compléter la phase avec : #{missing_siblings.first(2).join(', ')}"
        end
      end
    end

    suggestions
  end

  private

  # Met à jour les statuts des phases de la propriété
  def refresh_property_phase_statuses
    return unless property

    # Rafraîchir le statut de la phase concernée
    if document_phase
      property.phase_status_for(document_phase).refresh_status!
    end

    # Rafraîchir tous les statuts si c'est un document critique
    property.refresh_all_phase_statuses! if required_for_phase?
  end

  private

  def file_or_url_present
    unless file.attached? || file_url.present?
      errors.add(:base, "Un fichier ou une URL doit être fourni")
    end
  end

  def file_size_limit
    return unless file.attached?

    if file.byte_size > MAX_FILE_SIZE
      errors.add(:file, "ne doit pas dépasser #{ActionController::Base.helpers.number_to_human_size(MAX_FILE_SIZE)}")
    end
  end

  def file_format_validation
    return unless file.attached?

    unless ALL_ALLOWED_FORMATS.include?(file.content_type)
      errors.add(:file, "format non autorisé. Formats acceptés: PDF, images (JPEG, PNG, GIF, WebP), documents Word/Excel")
    end
  end
end
