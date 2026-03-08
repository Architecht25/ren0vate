class Prime < ApplicationRecord
  belongs_to :category
  has_many :works
  has_many :request_progresses
  has_many :document_templates, class_name: 'PrimeDocumentTemplate', dependent: :destroy

  validates :slug, :titre, presence: true
  validates :slug, uniqueness: true

  scope :par_ordre_affichage, -> { order(:ordre_affichage) }

  # Méthode pour récupérer les documents requis
  def required_documents
    document_templates.required_docs.by_order
  end

  # Méthode pour vérifier si des documents sont disponibles
  def has_documents?
    document_templates.exists?
  end

end
