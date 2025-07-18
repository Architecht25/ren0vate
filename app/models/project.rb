class Project < ApplicationRecord
  belongs_to :user
  belongs_to :property, optional: true
  belongs_to :request, optional: true
  has_many :works, dependent: :destroy
  has_many :documents, dependent: :destroy

  validates :nom, presence: true

  # Méthode pour affichage
  def name
    nom
  end

  # Méthode pour compatibilité
  def display_name
    "#{nom} (#{property&.name || 'Sans bien associé'})"
  end
end
