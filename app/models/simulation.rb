class Simulation < ApplicationRecord
  belongs_to :user
  belongs_to :property, optional: true
  has_many :simulation_prime_cards, dependent: :destroy
  has_many :primes, through: :simulation_prime_cards
  has_many :documents

  has_one :request

  validates :region, :titre, presence: true

  # Scope pour récupérer les simulations récentes
  scope :recent, -> { order(created_at: :desc) }

  # Méthodes utiles pour l'interface
  def total_primes_amount
    simulation_prime_cards.sum(:montant)
  end

  def eligibility_status
    case eligible
    when true
      'eligible'
    when false
      'not_eligible'
    else
      'pending'
    end
  end

  def processing_step
    return 1 unless eligible.present?
    return 2 if eligible && category.blank?
    return 3 if eligible && category.present? && simulation_prime_cards.empty?
    return 4 if eligible && category.present? && simulation_prime_cards.any?
  end

  def step_name
    case processing_step
    when 1
      'Test d\'éligibilité'
    when 2
      'Détermination de la catégorie'
    when 3
      'Calcul des primes'
    when 4
      'Simulation terminée'
    end
  end
end
