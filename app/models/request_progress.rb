class RequestProgress < ApplicationRecord
  belongs_to :request
  belongs_to :prime, optional: true

  # Relations pour la gestion des compléments
  has_many :complement_requests, dependent: :destroy

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

  # Validation pour s'assurer qu'on a soit une prime, soit un formulaire
  validate :prime_or_form_present

  private

  def prime_or_form_present
    if prime_id.blank? && form_type.blank?
      errors.add(:base, "Une prime ou un type de formulaire doit être spécifié")
    end
  end

  public

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

  # Délais de réponse par région (en mois)
  DELAIS_REPONSE = {
    'flandre' => 5,
    'bruxelles' => 4,
    'wallonie' => 24
  }.freeze

  # Méthodes pour le calcul du temps restant
  def delai_reponse_mois
    DELAIS_REPONSE[region&.downcase] || 6 # défaut si région inconnue
  end

  def date_limite_reponse
    return nil unless date_soumission
    date_soumission + delai_reponse_mois.months
  end

  def jours_restants
    return nil unless date_limite_reponse
    (date_limite_reponse - Date.current).to_i
  end

  def temps_restant_humanise
    return "Date de soumission manquante" unless date_soumission

    jours = jours_restants
    return "Délai dépassé" if jours < 0

    if jours == 0
      "Expire aujourd'hui"
    elsif jours == 1
      "1 jour restant"
    elsif jours < 30
      "#{jours} jours restants"
    elsif jours < 365
      mois = (jours / 30.0).round(1)
      if mois == mois.to_i
        "#{mois.to_i} mois restant#{'s' if mois.to_i > 1}"
      else
        "#{mois} mois restants"
      end
    else
      annees = (jours / 365.0).round(1)
      "#{annees} an#{'s' if annees > 1} restant#{'s' if annees > 1}"
    end
  end

  def statut_delai
    return :inconnu unless date_soumission

    jours = jours_restants
    return :depasse if jours < 0
    return :urgent if jours <= 30
    return :proche if jours <= 90
    :normal
  end

  def classe_css_delai
    case statut_delai
    when :depasse
      'text-danger fw-bold'
    when :urgent
      'text-warning fw-bold'
    when :proche
      'text-info'
    else
      'text-success'
    end
  end

  # Méthodes pour le tracking email
  def has_extracted_data?
    extracted_data.present?
  end

  def tracking_email_domain
    email_suivi&.split('@')&.last
  end

  def is_tracking_email_valid?
    tracking_email_domain == 'tracking.ren0vate.be'
  end

  def send_test_notification(user_email = 'robin@primes-services.be')
    TrackingEmailTestService.new(self).send_test_notification_to_user(user_email)
  end

  def simulate_admin_response(from_email = 'robin@primes-services.be')
    TrackingEmailTestService.new(self).simulate_admin_email_response(from_email)
  end

  def test_full_email_cycle(user_email = 'robin@primes-services.be')
    TrackingEmailTestService.new(self).run_full_test_cycle(user_email)
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

  def taux_octroi
    return 0 if montant_demande.blank? || montant_demande.zero?
    return 0 if montant_accorde.blank?

    (montant_accorde / montant_demande * 100).round(2)
  end

  # Méthodes pour la gestion des compléments
  def has_pending_complements?
    complement_requests.active.any?
  end

  def create_complement_request!(admin_message, complement_type = 'missing_documents', options = {})
    complement_requests.create!(
      admin_message: admin_message,
      complement_type: complement_type,
      deadline: options[:deadline] || calculate_complement_deadline(complement_type),
      required_documents: options[:required_documents] || [],
      priority: options[:priority] || 'normal'
    )
  end

  def process_complement_response!
    # Traiter la réponse du client au complément
    if complement_requests.active.all?(&:completed?)
      update!(status_administratif: 'en_cours')
      Rails.logger.info "RequestProgress #{id}: Tous les compléments traités, reprise du traitement"
    end
  end

  def handle_complement_expiry!
    # Gérer l'expiration d'une demande de complément
    expired_complements = complement_requests.overdue

    if expired_complements.any?
      expired_complements.update_all(status: 'expired')

      # Décider de l'action à prendre
      if critical_complements_expired?
        update!(status_administratif: 'annule')
        Rails.logger.warn "RequestProgress #{id}: Compléments critiques expirés, dossier annulé"
      else
        # Continuer avec les informations disponibles
        Rails.logger.info "RequestProgress #{id}: Compléments non-critiques expirés, traitement continue"
      end
    end
  end

  def resume_processing!
    # Reprendre le traitement après validation des compléments
    update!(status_administratif: 'en_cours')

    # Relancer l'analyse si nécessaire
    if request.project
      validation_service = TechnicalValidationService.new(request.project)
      result = validation_service.validate!

      if result[:valid]
        Rails.logger.info "RequestProgress #{id}: Validation technique OK après compléments"
      else
        Rails.logger.warn "RequestProgress #{id}: Problèmes techniques persistants après compléments"
      end
    end
  end

  def complement_summary
    {
      total_requests: complement_requests.count,
      active_requests: complement_requests.active.count,
      completed_requests: complement_requests.completed.count,
      expired_requests: complement_requests.where(status: 'expired').count,
      average_response_time: calculate_average_response_time,
      completion_rate: calculate_completion_rate
    }
  end

  private

  def calculate_complement_deadline(complement_type)
    days = case complement_type
    when 'missing_documents' then 15
    when 'technical_clarification' then 10
    when 'document_quality' then 7
    when 'eligibility_verification' then 20
    else 14
    end

    days.days.from_now.to_date
  end

  def critical_complements_expired?
    complement_requests.where(
      status: 'expired',
      complement_type: ['missing_documents', 'eligibility_verification']
    ).any?
  end

  def calculate_average_response_time
    completed_complements = complement_requests.where(status: 'completed')
    return 0 if completed_complements.empty?

    total_days = completed_complements.sum do |complement|
      (complement.completed_at.to_date - complement.created_at.to_date).to_i
    end

    (total_days.to_f / completed_complements.count).round(1)
  end

  def calculate_completion_rate
    total = complement_requests.count
    return 0 if total.zero?

    completed = complement_requests.where(status: 'completed').count
    (completed.to_f / total * 100).round
  end

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

    if document_suivi_pdf.blob.byte_size > 30.megabytes
      errors.add(:document_suivi_pdf, 'must be less than 30MB')
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
