class Category < ApplicationRecord
  has_many :primes

  validates :code, :description, :region, presence: true
  validates :code, uniqueness: { scope: :region }

  # Scopes pour faciliter les requêtes par région
  scope :wallonie, -> { where(region: 'wallonie') }
  scope :bruxelles, -> { where(region: 'bruxelles') }
  scope :flandre, -> { where(region: 'flandre') }

  # Méthode utilitaire pour récupérer les catégories d'une région
  def self.for_region(region)
    where(region: region)
  end

  # Méthode pour vérifier l'éligibilité selon les revenus
  def eligible_for_income?(household_income, family_composition = {})
    return false unless household_income.present?

    # Calcul du seuil selon la composition familiale
    applicable_threshold = calculate_income_threshold(family_composition)

    household_income <= applicable_threshold
  end

  private

  def calculate_income_threshold(family_composition)
    base_threshold = family_composition[:is_couple] ? couple_sans_charge : seuil_seul
    return 0 unless base_threshold

    # Ajouter majoration par personne à charge
    additional_persons = (family_composition[:children_count] || 0) +
                        (family_composition[:elderly_dependents] || 0)

    base_threshold + (additional_persons * (increment_par_personne || 0))
  end
end
