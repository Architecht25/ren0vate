class ContractorSignature < ApplicationRecord
  belongs_to :request
  belongs_to :user, optional: true # L'entrepreneur s'il a un compte

  # Attachements pour les documents signés
  has_many_attached :signed_annexes
  has_many_attached :technical_certificates

  validates :contractor_name, presence: true
  validates :contractor_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :contractor_phone, presence: true
  validates :work_description, presence: true
  validates :status, presence: true

  # Enum pour les statuts
  enum :status, {
    pending: 'pending',           # En attente d'envoi
    sent: 'sent',                # Envoyé à l'entrepreneur
    viewed: 'viewed',            # Consulté par l'entrepreneur
    signed: 'signed',            # Signé et retourné
    rejected: 'rejected',        # Refusé par l'entrepreneur
    expired: 'expired'           # Délai dépassé
  }

  # Enum pour les types de travaux
  enum :work_type, {
    isolation: 'isolation',
    chauffage: 'chauffage',
    chassis: 'chassis',
    ventilation: 'ventilation',
    toiture: 'toiture',
    autres: 'autres'
  }

  # Callbacks
  before_create :generate_signature_token
  before_create :set_expiry_date
  after_update :notify_status_change

  # Scopes
  scope :pending_signature, -> { where(status: ['pending', 'sent', 'viewed']) }
  scope :completed, -> { where(status: ['signed', 'rejected']) }
  scope :expired_signatures, -> { where('expiry_date < ? AND status NOT IN (?)', Date.current, ['signed', 'rejected']) }

  # Méthodes
  def expired?
    expiry_date && expiry_date < Date.current && !completed?
  end

  def completed?
    signed? || rejected?
  end

  def days_until_expiry
    return 0 if expired?
    return nil unless expiry_date

    (expiry_date - Date.current).to_i
  end

  def signature_url
    Rails.application.routes.url_helpers.contractor_signature_url(signature_token)
  end

  def send_signature_request!
    return false if completed?

    update!(status: 'sent', sent_at: Time.current)
    ContractorSignatureMailer.signature_request(self).deliver_now
    true
  rescue => e
    Rails.logger.error "Erreur envoi signature entrepreneur #{id}: #{e.message}"
    false
  end

  def mark_as_viewed!
    update!(status: 'viewed', viewed_at: Time.current) if sent?
  end

  def mark_as_signed!(signature_data = {})
    update!(
      status: 'signed',
      signed_at: Time.current,
      signature_data: signature_data
    )

    # Mettre à jour le statut de la demande
    request.update_contractor_status!
  end

  def mark_as_rejected!(rejection_reason = nil)
    update!(
      status: 'rejected',
      rejected_at: Time.current,
      rejection_reason: rejection_reason
    )

    # Notifier le client
    request.notify_contractor_rejection!
  end

  # Validation des annexes techniques
  def validate_technical_requirements
    errors = []

    case work_type
    when 'isolation'
      errors << 'Certificat de performance thermique manquant' unless has_thermal_certificate?
      errors << 'Épaisseur d\'isolant non spécifiée' unless thickness_specified?
    when 'chauffage'
      errors << 'Certificat de conformité gaz/élec manquant' unless has_compliance_certificate?
      errors << 'Rendement énergétique non documenté' unless efficiency_documented?
    when 'chassis'
      errors << 'Certificat Uw manquant' unless has_uw_certificate?
    end

    errors
  end

  def generate_completion_report
    {
      contractor: {
        name: contractor_name,
        email: contractor_email,
        phone: contractor_phone
      },
      work: {
        type: work_type,
        description: work_description,
        estimated_amount: estimated_amount
      },
      signature: {
        status: status,
        signed_at: signed_at,
        viewed_at: viewed_at,
        sent_at: sent_at
      },
      documents: {
        signed_annexes_count: signed_annexes.count,
        certificates_count: technical_certificates.count
      },
      validation: {
        technical_errors: validate_technical_requirements,
        compliance_score: calculate_compliance_score
      }
    }
  end

  private

  def generate_signature_token
    self.signature_token = SecureRandom.urlsafe_base64(32)
  end

  def set_expiry_date
    self.expiry_date = 30.days.from_now
  end

  def notify_status_change
    return unless status_changed?

    case status
    when 'signed'
      ContractorSignatureMailer.signature_completed(self).deliver_later
    when 'rejected'
      ContractorSignatureMailer.signature_rejected(self).deliver_later
    when 'expired'
      ContractorSignatureMailer.signature_expired(self).deliver_later
    end
  end

  def has_thermal_certificate?
    technical_certificates.any? { |cert| cert.filename.to_s.include?('thermique') }
  end

  def thickness_specified?
    work_description&.match?(/\d+\s*(cm|mm)/)
  end

  def has_compliance_certificate?
    technical_certificates.any? { |cert| cert.filename.to_s.include?('conformite') }
  end

  def efficiency_documented?
    work_description&.match?(/rendement|efficacité|performance/)
  end

  def has_uw_certificate?
    technical_certificates.any? { |cert| cert.filename.to_s.include?('uw') }
  end

  def calculate_compliance_score
    total_requirements = case work_type
    when 'isolation' then 4
    when 'chauffage' then 4
    when 'chassis' then 3
    else 2
    end

    errors = validate_technical_requirements
    met_requirements = total_requirements - errors.count

    (met_requirements.to_f / total_requirements * 100).round
  end
end
