# Service pour calculer l'économie réalisée avec notre modèle SaaS vs chasseur de primes traditionnel
class SavingsCalculatorService
  # Pourcentage des chasseurs de primes traditionnels (HTVA)
  CHASSEUR_COMMISSION_RATE = 0.125 # 12.5%

  # Prix des abonnements par région (TTC en euros)
  SUBSCRIPTION_PRICES = {
    'wallonie' => 29.99,
    'flandre' => 29.99,
    'bruxelles' => 34.99
  }.freeze

  # Durée des abonnements par région (en mois)
  SUBSCRIPTION_DURATIONS = {
    'wallonie' => 24,
    'flandre' => 29,
    'bruxelles' => 18
  }.freeze

  def initialize(simulation_total, region)
    @simulation_total = simulation_total.to_f
    @region = region&.downcase
  end

  def calculate_savings
    return nil if @simulation_total <= 0 || @region.blank?

    {
      chasseur_cost: chasseur_cost,
      saas_cost: saas_cost,
      savings_amount: savings_amount,
      savings_percentage: savings_percentage,
      subscription_details: subscription_details
    }
  end

  def significant_savings?
    savings_amount > 250 # Seuil ajusté pour affichage plus fréquent
  end

  private

  def chasseur_cost
    @chasseur_cost ||= (@simulation_total * CHASSEUR_COMMISSION_RATE * 1.21).round(2) # +21% TVA
  end

  def saas_cost
    return 0 unless subscription_price && subscription_duration

    @saas_cost ||= (subscription_price * subscription_duration).round(2)
  end

  def savings_amount
    @savings_amount ||= (chasseur_cost - saas_cost).round(2)
  end

  def savings_percentage
    return 0 if chasseur_cost <= 0

    ((savings_amount / chasseur_cost) * 100).round(1)
  end

  def subscription_price
    SUBSCRIPTION_PRICES[@region]
  end

  def subscription_duration
    SUBSCRIPTION_DURATIONS[@region]
  end

  def subscription_details
    {
      monthly_price: subscription_price,
      duration_months: subscription_duration,
      region: @region
    }
  end
end
