module SimulationsHelper
  # Calcule et formate les économies par rapport à un chasseur de primes
  def calculate_savings_vs_chasseur(simulation)
    return nil unless simulation.total_simule&.positive? && simulation.region.present?

    savings_calculator = SavingsCalculatorService.new(simulation.total_simule, simulation.region)
    savings_calculator.calculate_savings
  end

  # Vérifie si les économies sont suffisamment importantes pour être affichées
  def show_savings_comparison?(simulation)
    savings_data = calculate_savings_vs_chasseur(simulation)
    savings_data && savings_data[:savings_amount] > 500
  end

  # Formate le message d'économie
  def savings_message(savings_data)
    return nil unless savings_data

    amount = number_to_currency(savings_data[:savings_amount], locale: :fr)
    percentage = savings_data[:savings_percentage]

    "Économisez #{amount} (#{percentage}%) vs un chasseur de primes"
  end

  # Retourne l'icône appropriée selon l'ampleur des économies
  def savings_icon(savings_data)
    return 'bi-piggy-bank' unless savings_data

    case savings_data[:savings_amount]
    when 0..999
      'bi-piggy-bank'
    when 1000..2499
      'bi-piggy-bank-fill'
    else
      'bi-currency-euro'
    end
  end

  # Classe CSS selon l'ampleur des économies
  def savings_css_class(savings_data)
    return 'alert-info' unless savings_data

    case savings_data[:savings_amount]
    when 0..999
      'alert-info'
    when 1000..2499
      'alert-success'
    else
      'alert-warning'
    end
  end
end
