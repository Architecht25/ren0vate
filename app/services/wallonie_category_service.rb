class WallonieCategoryService
  def initialize(params)
    @params = params
    @statut = params[:statut_familial]
    @enfants = params[:enfants_charge].to_i
    @agees = params[:personnes_agees_charge].to_i
    @revenu_tranche = params[:revenu_net]
  end

  def estimate_category
    category = determine_category_from_income

    {
      category: category,
      color: category_color(category),
      details: category_details(category)
    }
  end

  private

  def determine_category_from_income
    case @revenu_tranche
    when "r1"
      "R1"
    when "r2"
      "R2"
    when "r3"
      "R3"
    when "r4"
      "R4"
    when "r5"
      "R5"
    else
      "R4" # Défaut
    end
  end

  def category_color(category)
    case category
    when "R1"
      "success"    # Vert - Prime la plus élevée
    when "R2"
      "info"       # Bleu
    when "R3"
      "warning"    # Jaune
    when "R4"
      "secondary"  # Gris
    when "R5"
      "danger"     # Rouge - Prime la plus faible
    else
      "secondary"
    end
  end

  def category_details(category)
    case category
    when "R1"
      "Revenus très faibles - Montants de primes les plus élevés"
    when "R2"
      "Revenus faibles - Montants de primes élevés"
    when "R3"
      "Revenus moyens - Montants de primes moyens"
    when "R4"
      "Revenus élevés - Montants de primes réduits"
    when "R5"
      "Revenus très élevés - Montants de primes minimaux"
    else
      "Catégorie à déterminer"
    end
  end
end
