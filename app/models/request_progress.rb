class RequestProgress < ApplicationRecord
  belongs_to :request
  belongs_to :prime

  # Attachements pour les documents de suivi
  has_one_attached :document_suivi_pdf    # PDF reçu de l'administration
  has_one_attached :document_suivi_photo  # Photo du courrier (Wallonie)

  # Validations personnalisées pour les fichiers
  validate :validate_document_suivi_pdf, if: -> { document_suivi_pdf.attached? }
  validate :validate_document_suivi_photo, if: -> { document_suivi_photo.attached? }

  validates :step, :pourcentage, presence: true
  validates :email_suivi, presence: true, uniqueness: true
  validates :status_administratif, inclusion: {
    in: %w[en_preparation soumis en_cours complet incomplet accorde refuse annule]
  }
  validates :montant_demande, :montant_accorde, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Enum pour les statuts administratifs
  enum :status_administratif, {
    en_preparation: 'en_preparation',  # Dossier en cours de préparation
    soumis: 'soumis',                 # Soumis à l'administration
    en_cours: 'en_cours',             # En cours de traitement
    complet: 'complet',               # Dossier complet
    incomplet: 'incomplet',           # Dossier incomplet
    accorde: 'accorde',               # Prime accordée
    refuse: 'refuse',                 # Prime refusée
    annule: 'annule'                  # Demande annulée
  }

  # Enum pour le statut d'extraction des documents
  enum :document_extraction_status, {
    pending: 'pending',       # En attente de traitement
    processing: 'processing', # En cours de traitement
    completed: 'completed',   # Traitement terminé
    failed: 'failed'          # Échec du traitement
  }, prefix: :extraction

  # Callbacks
  before_validation :generate_email_suivi, on: :create, if: -> { email_suivi.blank? }
  after_update :update_date_derniere_maj, if: :status_administratif_changed?

  # Scopes
  scope :en_attente, -> { where(status_administratif: %w[soumis en_cours]) }
  scope :finalises, -> { where(status_administratif: %w[accorde refuse]) }
  scope :avec_documents, -> { where(document_recu: true) }

  # Méthodes
  def region
    request.region
  end

  def property
    request.property
  end

  def project
    request.project
  end

  def en_attente?
    %w[soumis en_cours].include?(status_administratif)
  end

  def finalise?
    %w[accorde refuse].include?(status_administratif)
  end

  def taux_octroi
    return 0 if montant_demande.blank? || montant_demande.zero?
    return 0 if montant_accorde.blank?

    (montant_accorde / montant_demande * 100).round(2)
  end

  # Méthodes pour le tracking email
  def has_extracted_data?
    extracted_data.present?
  end

  def parsed_extracted_data
    return {} if extracted_data.blank?

    begin
      JSON.parse(extracted_data)
    rescue JSON::ParserError
      {}
    end
  end

  def store_extracted_data(data)
    self.extracted_data = data.to_json if data.present?
    self.email_processed_at = Time.current
    self.document_extraction_status = 'completed'
  end

  def mark_extraction_failed(error_message = nil)
    self.document_extraction_status = 'failed'
    self.email_processed_at = Time.current

    # Optionnel: stocker l'erreur dans extracted_data
    if error_message
      self.extracted_data = { error: error_message, failed_at: Time.current }.to_json
    end
  end

  private
    return 0 if montant_demande.blank? || montant_demande.zero?
    return 0 if montant_accorde.blank?

    (montant_accorde / montant_demande * 100).round(2)
  end

  private

  def generate_email_suivi
    timestamp = Time.current.to_i
    property_id = request.property_id
    project_id = request.project_id || 'general'
    region = request.region

    self.email_suivi = "#{region}-#{property_id}-#{project_id}-#{timestamp}@tracking.ren0vate.be"
  end

  def update_date_derniere_maj
    self.date_derniere_maj = Date.current
  end

  def validate_document_suivi_pdf
    return unless document_suivi_pdf.attached?

    if document_suivi_pdf.blob.byte_size > 10.megabytes
      errors.add(:document_suivi_pdf, 'must be less than 10MB')
    end

    unless document_suivi_pdf.blob.content_type == 'application/pdf'
      errors.add(:document_suivi_pdf, 'must be a PDF file')
    end
  end

  def validate_document_suivi_photo
    return unless document_suivi_photo.attached?

    if document_suivi_photo.blob.byte_size > 5.megabytes
      errors.add(:document_suivi_photo, 'must be less than 5MB')
    end

    unless %w[image/jpeg image/jpg image/png image/gif].include?(document_suivi_photo.blob.content_type)
      errors.add(:document_suivi_photo, 'must be an image file (JPEG, PNG, or GIF)')
    end
  end
end
