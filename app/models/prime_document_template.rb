class PrimeDocumentTemplate < ApplicationRecord
  belongs_to :prime, optional: true

  # Active Storage pour les fichiers PDF
  has_one_attached :document_file

  # Validations
  validates :title, :type_document, presence: true
  validates :prime_id, uniqueness: { scope: :type_document }, allow_nil: true
  validate :file_or_url_present
  validate :prime_required_for_specific_types

  # Énumérations pour les types de documents
  enum :type_document, {
    attestation_entrepreneur: 'attestation_entrepreneur',
    attestation_generale: 'attestation_generale',
    formulaire_demande: 'formulaire_demande',
    annexe_technique: 'annexe_technique',
    guide_remplissage: 'guide_remplissage',
    certificat_conformite: 'certificat_conformite',
    fiche_technique: 'fiche_technique'
  }

  # Scopes
  scope :for_prime, ->(prime) { where(prime: prime) }
  scope :general_docs, -> { where(prime: nil) }
  scope :specific_docs, -> { where.not(prime: nil) }
  scope :required_docs, -> { where(is_required: true) }
  scope :by_order, -> {
    left_joins(:prime).order(
      Arel.sql('COALESCE(primes.ordre_affichage, 0) ASC'),
      :order_position,
      :title
    )
  }
  scope :by_type, ->(type) { where(type_document: type) }
  scope :by_region, ->(region) {
    left_joins(:prime).where(
      Arel.sql('primes.region = ? OR primes.region IS NULL'),
      region
    )
  }

  # Méthodes
  def file_available?
    document_file.attached? || file_url.present?
  end

  def download_url
    if document_file.attached?
      # Utiliser only_path: true pour éviter les problèmes d'host en développement
      Rails.application.routes.url_helpers.rails_blob_path(document_file)
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

  def prime_required_for_specific_types
    # Seuls certains types peuvent être généraux (sans prime associée)
    general_types = ['attestation_generale']

    if prime.nil? && !general_types.include?(type_document)
      errors.add(:prime, "doit être présente pour ce type de document")
    end
  end
end
