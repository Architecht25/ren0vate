class Property < ApplicationRecord
  belongs_to :user
  has_many :simulations
  has_many :projects
  has_many :requests
  has_many :documents

  # Validations pour les champs obligatoires
  validates :rue, :numero, :code_postal, :commune, :region, presence: true
  validates :type, :occupation, presence: true
  validates :annee_construction, :date_raccordement_electrique, :numero_ean, presence: true

  # Validations pour les champs radio
  validates :autre_bien, inclusion: { in: %w[oui non] }, allow_blank: true
  validates :peb, inclusion: { in: %w[ef autre] }, allow_blank: true

  # Méthode pour l'adresse complète
  def full_address
    "#{numero} #{rue}, #{code_postal} #{commune}"
  end

  # Méthode pour compatibilité avec les vues existantes
  def address
    full_address
  end

  def location
    full_address
  end
end
