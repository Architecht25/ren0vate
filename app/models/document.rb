class Document < ApplicationRecord
  belongs_to :user
  belongs_to :property, optional: true
  belongs_to :request, optional: true
  belongs_to :project, optional: true
  belongs_to :simulation, optional: true

  has_one_attached :file

  validates :file_url, :type_document, presence: true

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

  # Méthodes helper
  def completed?
    approved?
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
end
