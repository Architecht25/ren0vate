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
    devis: 'devis',
    facture: 'facture',
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
