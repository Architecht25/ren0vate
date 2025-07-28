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
    warnings = []

    # Question 1: Localisation du bien
    if @params[:localisation] == "non"
      reasons << "Le bien concerné par la demande doit être situé en Région de Bruxelles-Capitale"
    end

    # Question 2: Âge du bâtiment  
    if @params[:age_batiment] == "non"
      reasons << "Le bâtiment doit être âgé d'au moins 10 ans"
    end

    # Question 3: Professionnel agréé
    if @params[:professionnel_agree] == "non"
      reasons << "Les travaux doivent être réalisés par un professionnel inscrit à la Banque Carrefour des Entreprises qui dispose de l'accès réglementé à la profession"
    end

    # Question 4: Nouvelle construction
    if @params[:nouvelle_construction] == "oui"
      reasons << "Les nouvelles constructions ou ajouts considérés comme nouvelle construction ne sont pas éligibles"
    end

    # Question 5: Compte bancaire belge
    if @params[:compte_belge] == "non"
      reasons << "Un compte bancaire belge est requis pour le virement de la prime"
    end

    # Question 6: Travaux réalisés avec facture
    if @params[:travaux_realises] == "non"
      reasons << "Les travaux doivent être réalisés avec une facture de solde émise dans les 12 mois précédant la demande"
    end

    # Question 7: Primes déjà reçues
    if @params[:primes_recues] == "oui"
      warnings << "Des travaux identiques dans un même bien ne bénéficient d'une prime qu'une fois par période de 10 ans"
    end

    # Question 8: Propriétaire appartement + parties communes
    if @params[:proprietaire_appartement] == "oui" && @params[:parties_communes] == "oui"
      reasons << "Pour les travaux concernant les parties communes d'un immeuble, la demande doit être faite au nom de l'ACP (Association des Copropriétaires)"
    end

    # Question 14: Domiciliation
    if @params[:domiciliation] == "non"
      reasons << "Vous devez être domicilié à l'adresse du chantier au plus tard avant l'introduction de la demande"
    end

    # Question 15: Vente du bien dans les 5 ans
    if @params[:vente_bien] == "oui"
      warnings << "Si le montant de la prime perçue est supérieur à 30.000 EUR et en cas de vente ou de donation du bien concerné dans le délai de 5 ans, vous devrez rembourser le montant perçu"
    end

    # Question 16: Permis d'urbanisme
    if @params[:permis_urbanisme] == "non"
      warnings << "Certains travaux nécessitent un permis d'urbanisme, consultez le service urbanisme de votre commune"
    end

    # Informations positives (statuts avantageux)
    avantages = []
    if @params[:bim] == "oui"
      avantages << "Statut BIM : permet d'accéder au montant de primes le plus élevé"
    end
    if @params[:ris] == "oui"
      avantages << "Revenu d'intégration sociale (RIS) : permet d'accéder au montant de primes le plus élevé"
    end
    if @params[:client_protege] == "oui"
      avantages << "Client protégé régional : permet d'accéder aux montants de prime les plus élevés"
    end

    # Déterminer l'éligibilité
    eligible = reasons.empty?

    result = {
      eligible: eligible,
      message: eligible ? "Félicitations ! Vous êtes éligible aux primes RENOLUTION Bruxelles." : "Vous n'êtes pas éligible pour les raisons suivantes :",
      reasons: reasons,
      warnings: warnings,
      avantages: avantages,
      profile: "particulier"
    }

    # Informations spécifiques pour indépendants
    if @params[:independant] == "oui"
      independant_info = []
      if @params[:tva_deductible] == "oui"
        independant_info << "TVA déductible déclarée"
      end
      if @params[:usage_professionnel] == "oui" && @params[:surface_totale].present? && @params[:surface_professionnelle].present?
        independant_info << "Usage professionnel : #{@params[:surface_professionnelle]}m² sur #{@params[:surface_totale]}m² total"
      end
      result[:independant_info] = independant_info unless independant_info.empty?
    end

    result
  end

  def check_entreprise_eligibility
    reasons = []
    warnings = []
    infos = []

    # Question 1: Localisation du bien
    if @params[:localisation] == "non"
      reasons << "Le bien concerné par la demande doit être situé en Région de Bruxelles-Capitale"
    end

    # Question 2: Âge du bâtiment  
    if @params[:age_batiment] == "non"
      reasons << "Le bâtiment doit être âgé d'au moins 10 ans"
    end

    # Question 3: Professionnel agréé
    if @params[:professionnel_agree] == "non"
      reasons << "Les travaux doivent être réalisés par un professionnel inscrit à la Banque Carrefour des Entreprises qui dispose de l'accès réglementé à la profession"
    end

    # Question 4: Nouvelle construction
    if @params[:nouvelle_construction] == "oui"
      reasons << "Les nouvelles constructions ou ajouts considérés comme nouvelle construction ne sont pas éligibles"
    end

    # Question 5: Compte bancaire belge
    if @params[:compte_belge] == "non"
      reasons << "Un compte bancaire belge est requis pour le virement de la prime"
    end

    # Question 6: Travaux réalisés avec facture
    if @params[:travaux_realises] == "non"
      reasons << "Les travaux doivent être réalisés avec une facture de solde émise dans les 12 mois précédant la demande"
    end

    # Question 7: Primes déjà reçues
    if @params[:primes_recues] == "oui"
      warnings << "Des travaux identiques dans un même bien ne bénéficient d'une prime qu'une fois par période de 10 ans"
    end

    # Question 11: Enregistrement BCE
    if @params[:enregistrement_bce] == "non"
      reasons << "Pour introduire une demande de prime en tant que société, cette dernière doit être inscrite à la BCE"
    end

    # Informations sur le type de propriété
    propriete_info = []
    if @params[:proprietaire_immeuble] == "oui"
      propriete_info << "Propriétaire de tout l'immeuble"
      if @params[:quantite_appartements].present?
        propriete_info << "Quantité d'appartements : #{@params[:quantite_appartements]}"
      end
      
      case @params[:logement_80_pourcent]
      when "oui"
        propriete_info << "Avec au moins 80% de logement"
      when "non"
        propriete_info << "Avec moins de 80% de logement"
      when "sans"
        propriete_info << "Sans logement"
      end

      if @params[:usage_collectivite] == "oui"
        propriete_info << "Utilisé par une collectivité"
        if @params[:nom_collectivite].present?
          propriete_info << "Collectivité : #{@params[:nom_collectivite]}"
        end
        if @params[:code_nacebel].present?
          propriete_info << "Code Nacebel : #{@params[:code_nacebel]}"
        end
      end
    elsif @params[:proprietaire_appartement] == "oui"
      propriete_info << "Propriétaire d'un appartement résidentiel"
    elsif @params[:proprietaire_maison] == "oui"
      propriete_info << "Propriétaire d'une maison"
    end

    # Informations bail AIS
    if @params[:bail_ais] == "oui"
      infos << "Location via bail AIS (Agence Immobilière Sociale)"
    end

    # Informations TVA
    if @params[:tva_deductible] == "oui"
      tva_info = "TVA déductible"
      if @params[:pourcentage_tva].present?
        tva_info += " à #{@params[:pourcentage_tva]}%"
      end
      infos << tva_info
    end

    # Informations de minimis
    if @params[:de_minimis] == "oui"
      infos << "Activité économique sous réglementation européenne de minimis"
    end

    # Déterminer l'éligibilité
    eligible = reasons.empty?

    result = {
      eligible: eligible,
      message: eligible ? "Félicitations ! Votre entreprise est éligible aux primes RENOLUTION Bruxelles." : "Votre entreprise n'est pas éligible pour les raisons suivantes :",
      reasons: reasons,
      warnings: warnings,
      infos: infos,
      propriete_info: propriete_info,
      profile: "entreprise"
    }

    result
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
    warnings = []
    avantages = []
    infos = []

    # Question 1: Localisation
    if @params[:localisation] == "non"
      reasons << "L'ASBL et le bâtiment doivent être situés en Région de Bruxelles-Capitale"
    end

    # Question 2: Autres primes
    if @params[:autres_primes] == "oui"
      reasons << "Vous ne pouvez pas cumuler cette prime avec d'autres primes d'énergie pour le même bâtiment"
    end

    # Question 3: Usage collectivité
    if @params[:usage_collectivite] == "oui"
      reasons << "Ce bâtiment ne peut pas être utilisé par une collectivité ou administration publique"
    end

    # Question 4: Enregistrement BCE
    if @params[:enregistrement_bce] == "non"
      reasons << "L'ASBL doit être enregistrée à la BCE (Banque Carrefour des Entreprises)"
    end

    # Question 5: Type de bâtiment (informatif)
    if @params[:type_batiment].present?
      case @params[:type_batiment]
      when "bureau"
        infos << "Type de bâtiment : Bureau ou local administratif"
      when "centre_activites"
        infos << "Type de bâtiment : Centre d'activités ou accueil du public"
      when "local_technique"
        infos << "Type de bâtiment : Local technique ou stockage"
      when "mixte"
        infos << "Type de bâtiment : Usage mixte"
      end
    end

    # Question 6: Autorisation travaux
    if @params[:autorisation_travaux] == "non"
      reasons << "Vous devez être propriétaire du bâtiment ou avoir l'autorisation écrite du propriétaire pour réaliser les travaux"
    end

    # Question 7: Travaux commencés
    if @params[:travaux_commences] == "oui"
      reasons << "Les travaux ne doivent pas avoir commencé avant l'introduction de la demande de prime"
    end

    # Question 8 & Conditionnelle: Numéro TVA et déduction
    if @params[:numero_tva] == "oui"
      if @params[:tva_deduction] == "oui"
        reasons << "Si vous pouvez déduire la TVA sur les travaux, vous n'êtes pas éligible à cette prime"
      else
        infos << "ASBL avec numéro TVA mais sans déduction possible sur les travaux d'amélioration énergétique"
      end
    else
      avantages << "Pas de contraintes TVA pour votre ASBL"
    end

    # Question 9: Activités d'intérêt général
    if @params[:activites_interet_general] == "non"
      reasons << "L'ASBL doit exercer des activités d'intérêt général reconnues"
    else
      avantages << "ASBL reconnue d'intérêt général"
    end

    # Question 10: Secteur d'activité (informatif et avantages)
    if @params[:secteur_activite].present?
      case @params[:secteur_activite]
      when "social"
        avantages << "Secteur social : priorité dans le traitement des dossiers"
        infos << "Secteur d'activité : Social et aide aux personnes"
      when "culturel"
        avantages << "Secteur culturel : éligible aux bonifications spécifiques"
        infos << "Secteur d'activité : Culturel et artistique"
      when "educatif"
        avantages << "Secteur éducatif : primes majorées possibles"
        infos << "Secteur d'activité : Éducatif et formation"
      when "sportif"
        infos << "Secteur d'activité : Sportif et loisirs"
      when "environnemental"
        avantages << "Secteur environnemental : bonus développement durable"
        infos << "Secteur d'activité : Environnemental et écologique"
      when "autre"
        infos << "Secteur d'activité : Autre secteur d'intérêt général"
      end
    end

    # Question 11: Bénéficiaires
    if @params[:accueil_beneficiaires] == "oui"
      avantages << "Accueil régulier de bénéficiaires : critère favorable"
    else
      warnings << "Pas d'accueil régulier du public - impact possible sur certaines primes spécifiques"
    end

    # Question 12: Personnel permanent
    if @params[:personnel_permanent] == "oui"
      infos << "ASBL avec personnel permanent"
    else
      infos << "ASBL fonctionnant uniquement avec des bénévoles"
    end

    # Question 13: Utilisation régulière
    if @params[:utilisation_reguliere] == "non"
      reasons << "Le bâtiment doit être utilisé de manière régulière et continue pour les activités de l'ASBL"
    else
      avantages << "Utilisation régulière et continue du bâtiment"
    end

    # Question 14: Budget annuel (informatif et avantages)
    if @params[:budget_annuel].present?
      case @params[:budget_annuel]
      when "moins_25k"
        avantages << "Petit budget : éligible aux primes majorées pour petites structures"
        infos << "Budget annuel : Moins de 25 000€"
      when "25k_100k"
        infos << "Budget annuel : Entre 25 000€ et 100 000€"
      when "100k_500k"
        infos << "Budget annuel : Entre 100 000€ et 500 000€"
      when "plus_500k"
        infos << "Budget annuel : Plus de 500 000€"
        warnings << "Budget important - vérification approfondie du caractère non lucratif"
      end
    end

    # Question 15: Règlement de minimis
    if @params[:reglement_de_minimis] == "oui"
      warnings << "Attention au plafond de 200 000€ d'aides publiques sur 3 ans (règlement de minimis)"
    else
      avantages << "Pas de contrainte règlement de minimis"
    end

    # Question 16: Bâtiment conforme
    if @params[:batiment_conforme] == "non"
      reasons << "Le bâtiment doit être conforme à la réglementation en vigueur (permis d'urbanisme, normes de sécurité, accessibilité)"
    else
      avantages << "Bâtiment conforme à la réglementation"
    end

    eligible = reasons.empty?

    {
      eligible: eligible,
      message: eligible ? "Votre ASBL est éligible aux primes RENOLUTION." : "Votre ASBL n'est pas éligible pour les raisons suivantes :",
      reasons: reasons,
      warnings: warnings,
      avantages: avantages,
      infos: infos,
      profile: "asbl"
    }
  end
end
