class RequestProgress < ApplicationRecord
  belongs_to :request
  belongs_to :prime

  # Attachements pour les documents de suivi
  has_one_attached :document_suivi_pdf    # PDF reçu de l'administration
  has_one_attached :document_suivi_photo  # Photo du courrier (Wallonie)

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
end
