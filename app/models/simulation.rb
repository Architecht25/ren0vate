class Simulation < ApplicationRecord
  belongs_to :user
  belongs_to :property
  belongs_to :project, optional: true
  has_many :simulation_prime_cards, dependent: :destroy
  has_many :primes, through: :simulation_prime_cards
  has_many :documents, dependent: :destroy

  has_one :request, dependent: :destroy

  validates :region, :titre, :property_id, presence: true

  # Scope pour récupérer les simulations récentes
  scope :recent, -> { order(created_at: :desc) }

  # Méthodes utiles pour l'interface
  def total_primes_amount
    simulation_prime_cards.sum(:montant_simule)
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

  # Méthodes pour la double éligibilité (finalité économique)
  def dual_eligibility_status
    if project&.finalite_economique?
      {
        investment: investment_eligibility_status,
        renolution: renolution_eligibility_status
      }
    else
      nil
    end
  end

  def investment_eligibility_status
    case eligible_investment
    when true
      'eligible'
    when false
      'not_eligible'
    else
      'pending'
    end
  end

  def renolution_eligibility_status
    case eligible_renolution
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

  # Accès aux données de catégorie stockées dans parameters
  def exact_income
    return nil unless parameters.present?
    parsed_params = JSON.parse(parameters)
    parsed_params['exact_income']
  rescue JSON::ParserError
    nil
  end

  def thresholds_used
    return nil unless parameters.present?
    parsed_params = JSON.parse(parameters)
    parsed_params['thresholds_used']
  rescue JSON::ParserError
    nil
  end
end
