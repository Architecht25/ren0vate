class Prime < ApplicationRecord
  validates :slug, presence: true, uniqueness: true
  validates :titre, :unite, :type_de_valeur, :region, presence: true
  validates :eligible_categories, presence: true
  validates :valeurs_par_categorie, presence: true
  validates :image, presence: true

  # JSON validations de forme (à affiner avec custom validator si besoin)
  validate :validate_valeurs_par_categorie_structure
  validate :validate_placeholder_structure

  private

  def validate_valeurs_par_categorie_structure
    unless valeurs_par_categorie.is_a?(Hash)
      errors.add(:valeurs_par_categorie, "doit être une structure JSON valide")
    end
  end

  def validate_placeholder_structure
    unless placeholder.is_a?(Hash)
      errors.add(:placeholder, "doit être une structure JSON valide")
    end
  end
end
