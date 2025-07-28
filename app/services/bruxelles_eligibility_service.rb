class BruxellesEligibilityService
  def initialize(params)
    @params = params
    @profile_type = params[:profile_type]
  end

  def check_eligibility
    case @profile_type
    when "prive"
      check_particulier_eligibility
    when "entreprise"
      check_entreprise_eligibility
    when "syndic"
      check_syndic_eligibility
    when "bailleur"
      check_bailleur_eligibility
    when "asbl"
      check_asbl_eligibility
    else
      {
        eligible: false,
        message: "Type de profil non reconnu",
        reasons: []
      }
    end
  end

  private

  def check_particulier_eligibility
    reasons = []

    # Question 1: Localisation
    if @params[:localisation] == "non"
      reasons << "Le logement doit être situé en Région de Bruxelles-Capitale"
    end

    # Question 2: Propriété
    if @params[:proprietaire] == "non"
      reasons << "Vous devez être propriétaire du logement pour bénéficier des primes"
    end

    # Question 3: Résidence principale
    if @params[:residence_principale] == "non"
      reasons << "Le logement doit être votre résidence principale"
    end

    # Question 4: Âge du bâtiment
    if @params[:age_batiment] == "non"
      reasons << "Le bâtiment doit avoir été construit il y a plus de 10 ans"
    end

    # Question 5: Compte bancaire belge
    if @params[:compte_belge] == "non"
      reasons << "Un compte bancaire belge est requis pour le versement des primes"
    end

    # Déterminer l'éligibilité
    eligible = reasons.empty?

    {
      eligible: eligible,
      message: eligible ? "Félicitations ! Vous êtes éligible aux primes RENOLUTION." : "Vous n'êtes pas éligible pour les raisons suivantes :",
      reasons: reasons,
      profile: "particulier"
    }
  end

  def check_entreprise_eligibility
    reasons = []

    # Question 1: Localisation
    if @params[:localisation] == "non"
      reasons << "L'entreprise et le bâtiment doivent être situés en Région de Bruxelles-Capitale"
    end

    # Question 2: PME
    if @params[:est_pme] == "non"
      reasons << "Seules les PME (moins de 250 employés) sont éligibles aux primes"
    end

    # Question 3: Autorisation travaux
    if @params[:autorisation_travaux] == "non"
      reasons << "Vous devez être propriétaire ou avoir l'autorisation du propriétaire"
    end

    # Question 4: Usage professionnel
    if @params[:usage_professionnel] == "non"
      reasons << "Le bâtiment doit être destiné exclusivement à l'activité professionnelle"
    end

    # Question 5: Compte bancaire belge
    if @params[:compte_belge] == "non"
      reasons << "Un compte bancaire belge est requis pour le versement des primes"
    end

    eligible = reasons.empty?

    {
      eligible: eligible,
      message: eligible ? "Votre entreprise est éligible aux primes RENOLUTION." : "Votre entreprise n'est pas éligible pour les raisons suivantes :",
      reasons: reasons,
      profile: "entreprise"
    }
  end

  def check_syndic_eligibility
    reasons = []

    # Question 1: Localisation
    if @params[:localisation] == "non"
      reasons << "L'immeuble doit être situé en Région de Bruxelles-Capitale"
    end

    # Question 2: Usage résidentiel
    if @params[:usage_residentiel] == "non"
      reasons << "L'immeuble doit être principalement résidentiel (au moins 80% logement)"
    end

    # Question 3: Âge immeuble
    if @params[:age_immeuble] == "non"
      reasons << "L'immeuble doit avoir été construit il y a plus de 10 ans"
    end

    # Question 4: Minimum unités
    if @params[:minimum_unites] == "non"
      reasons << "La copropriété doit compter au moins 2 unités"
    end

    eligible = reasons.empty?

    {
      eligible: eligible,
      message: eligible ? "La copropriété est éligible aux primes RENOLUTION." : "La copropriété n'est pas éligible pour les raisons suivantes :",
      reasons: reasons,
      profile: "syndic"
    }
  end

  def check_bailleur_eligibility
    reasons = []

    # Question 1: Agrément AIS
    if @params[:agrement_ais] == "non"
      reasons << "Un agrément AIS (Agence Immobilière Sociale) est requis"
    end

    # Question 2: Localisation
    if @params[:localisation] == "non"
      reasons << "Les logements doivent être situés en Région de Bruxelles-Capitale"
    end

    # Question 3: Logement social
    if @params[:logement_social] == "non"
      reasons << "Vous devez gérer au moins un logement destiné au logement social"
    end

    # Question 4: Compte bancaire belge
    if @params[:compte_belge] == "non"
      reasons << "Un compte bancaire belge est requis pour le versement des primes"
    end

    eligible = reasons.empty?

    {
      eligible: eligible,
      message: eligible ? "Votre AIS est éligible aux primes RENOLUTION." : "Votre AIS n'est pas éligible pour les raisons suivantes :",
      reasons: reasons,
      profile: "bailleur"
    }
  end

  def check_asbl_eligibility
    reasons = []

    # Question 1: Localisation
    if @params[:localisation] == "non"
      reasons << "L'ASBL et le bâtiment doivent être situés en Région de Bruxelles-Capitale"
    end

    # Question 2: Secteur éligible
    if @params[:secteur_eligible] == "non"
      reasons << "L'ASBL doit exercer ses activités dans le secteur social, culturel ou d'intérêt général"
    end

    # Question 3: Autorisation travaux
    if @params[:autorisation_travaux] == "non"
      reasons << "Vous devez être propriétaire ou avoir l'autorisation du propriétaire"
    end

    # Question 4: Usage ASBL
    if @params[:usage_asbl] == "non"
      reasons << "Le bâtiment doit être destiné aux activités de l'ASBL (pas résidentiel)"
    end

    # Question 5: Accueil public
    if @params[:accueil_public] == "non"
      reasons << "L'ASBL doit accueillir régulièrement du public ou des bénéficiaires"
    end

    eligible = reasons.empty?

    {
      eligible: eligible,
      message: eligible ? "Votre ASBL est éligible aux primes RENOLUTION." : "Votre ASBL n'est pas éligible pour les raisons suivantes :",
      reasons: reasons,
      profile: "asbl"
    }
  end
end
