class MunicipalForm < ApplicationRecord
  # Modèle pour gérer les formulaires communaux
  # Ce modèle pourra être utilisé plus tard pour stocker
  # des informations spécifiques aux formulaires communaux
  
  validates :name, presence: true, if: -> { respond_to?(:name) }
  
  # Scopes pour filtrer par région
  scope :by_region, ->(region) { where(region: region) if respond_to?(:region) }
  
  # Méthodes helper
  def display_name
    name.presence || "Formulaire municipal"
  end
end