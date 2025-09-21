class PrimeDocumentTemplate < ApplicationRecord
  belongs_to :prime

  # Active Storage pour les fichiers PDF
  has_one_attached :document_file

  # Validations
  validates :title, :type_document, presence: true
  validates :prime_id, uniqueness: { scope: :type_document }
  validate :file_or_url_present

  # Énumérations pour les types de documents
  enum :type_document, {
    attestation_entrepreneur: 'attestation_entrepreneur',
    formulaire_demande: 'formulaire_demande',
    annexe_technique: 'annexe_technique',
    guide_remplissage: 'guide_remplissage',
    certificat_conformite: 'certificat_conformite',
    fiche_technique: 'fiche_technique'
  }

  # Scopes
  scope :for_prime, ->(prime) { where(prime: prime) }
  scope :required_docs, -> { where(is_required: true) }
  scope :by_order, -> { 
    joins(:prime).order(
      Arel.sql("
        CASE 
          WHEN primes.titre ~ '^[A-Z][0-9]' THEN 
            CONCAT(
              SUBSTRING(primes.titre FROM '^([A-Z])'),
              LPAD(SUBSTRING(primes.titre FROM '^[A-Z]([0-9]+)'), 3, '0')
            )
          ELSE primes.titre 
        END
      "),
      :order_position, 
      :title
    )
  }
  scope :by_type, ->(type) { where(type_document: type) }
  scope :by_region, ->(region) { joins(:prime).where(primes: { region: region }) }

  # Méthodes
  def file_available?
    document_file.attached? || file_url.present?
  end

  def download_url
    if document_file.attached?
      Rails.application.routes.url_helpers.rails_blob_url(document_file, only_path: false)
    else
      file_url
    end
  end

  def file_name
    if document_file.attached?
      document_file.filename.to_s
    elsif file_url.present?
      File.basename(file_url)
    else
      "#{title.parameterize}.pdf"
    end
  end

  private

  def file_or_url_present
    unless document_file.attached? || file_url.present?
      errors.add(:base, "Un fichier ou une URL doit être fourni")
    end
  end
end
