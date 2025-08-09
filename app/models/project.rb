class Project < ApplicationRecord
  belongs_to :user
  belongs_to :property
  belongs_to :request, optional: true
  has_many :works, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :simulations, dependent: :destroy  # Ajouter cette ligne

  validates :nom, presence: true
  validates :property_id, presence: true

  # Définir un statut par défaut
  before_validation :set_default_status

  # Méthode pour affichage
  def name
    nom
  end

  # Méthode pour compatibilité
  def display_name
    "#{nom} (#{property&.name || 'Sans bien associé'})"
  end

  private

  def set_default_status
    self.statut ||= 'preparation'
  end
end
