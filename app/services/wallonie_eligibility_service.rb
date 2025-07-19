class WallonieEligibilityService
  def initialize(params)
    @params = params
  end

  def check_eligibility
    # Critères d'inéligibilité (réponse "non" = éliminatoire)
    return ineligible("Le logement doit être situé en Wallonie") if @params[:localisation] == "non"
    return ineligible("Le bien doit être destiné à être habité à minimum 50%") if @params[:destination] == "non"
    return ineligible("Vous devez être propriétaire du logement") if @params[:propriete] == "non"
    return ineligible("Le logement doit être occupé comme résidence principale") if @params[:residence_principale] == "non"
    return ineligible("Le logement doit avoir plus de 15 ans") if @params[:age_logement] == "non"
    return ineligible("Un audit énergétique est requis") if @params[:audit] == "non"
    return ineligible("L'entrepreneur doit être inscrit à la BCE") if @params[:entrepreneur] == "non"
    return ineligible("Les factures doivent dater de moins de 2 ans") if @params[:factures_anciennes] == "oui"

    # Logique de catégorie selon les revenus
    if @params[:revenus] == "non"
      # Revenus <= 114 400€ → Besoin d'affinage R1-R4
      eligible_with_refinement
    else
      # Revenus > 114 400€ → Catégorie R5 directe
      eligible_category_r5
    end
  end

  private

  def ineligible(message)
    {
      eligible: false,
      message: message,
      category: nil,
      needs_refinement: false
    }
  end

  def eligible_with_refinement
    {
      eligible: true,
      message: "Éligible aux primes",
      category: "R1-R4",
      needs_refinement: true
    }
  end

  def eligible_category_r5
    {
      eligible: true,
      message: "Éligible aux primes",
      category: "R5",
      needs_refinement: false
    }
  end
end
