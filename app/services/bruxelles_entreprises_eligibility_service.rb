class BruxellesEntreprisesEligibilityService
  attr_reader :params

  def initialize(params)
    @params = params
    Rails.logger.info "🏢 Service d'éligibilité Bruxelles Entreprises initialisé avec: #{params.inspect}"
  end

  def check_eligibility
    Rails.logger.info "🎯 Début vérification éligibilité entreprise Bruxelles"

    # Vérifications d'éligibilité de base
    return ineligible("❌ Le siège d'exploitation doit être situé en Région de Bruxelles-Capitale") if params[:localisation] == "non"
    return ineligible("❌ L'entreprise doit être active dans un secteur d'activité éligible") if params[:secteur_eligible] == "non"
    return ineligible("❌ L'entreprise doit être une PME (moins de 250 employés)") if params[:taille_entreprise] == "grande"
    return ineligible("❌ L'entreprise doit avoir une finalité économique et ne pas être publique") if params[:finalite_economique] == "non"
    return ineligible("❌ L'entreprise ne peut pas avoir reçu plus de 300.000€ d'aides de minimis sur 3 ans") if params[:de_minimis] == "oui"
    return ineligible("❌ Un numéro d'entreprise BCE valide est requis") if params[:numero_bce] == "non"

    # Si toutes les vérifications passent, l'entreprise est éligible
    eligible_result = {
      eligible: true,
      message: build_success_message,
      recommendations: build_recommendations,
      subsidy_categories: build_subsidy_categories
    }

    Rails.logger.info "✅ Entreprise éligible: #{eligible_result}"
    eligible_result
  end

  private

  def ineligible(message)
    Rails.logger.info "❌ Entreprise non éligible: #{message}"
    {
      eligible: false,
      message: message,
      recommendations: [
        "Vérifiez les critères d'éligibilité",
        "Consultez le site officiel economie-emploi.brussels",
        "Contactez Bruxelles Economie et Emploi pour plus d'informations"
      ]
    }
  end

  def build_success_message
    company_size = determine_company_size
    message = "✅ Votre entreprise est éligible aux aides de Bruxelles Economie et Emploi !"
    message += "<br><br><strong>Taille d'entreprise :</strong> <span class='badge bg-info'>#{company_size}</span>"

    # Ajouter les majorations possibles
    majorations = []
    majorations << "Starter (+15%)" if params[:entreprise_starter] == "oui"
    majorations << "Exemplaire environnemental (+15%)" if params[:exemplaire_environnemental] == "oui"
    majorations << "Exemplaire social (+15%)" if params[:exemplaire_social] == "oui"

    if majorations.any?
      message += "<br><strong>Majorations applicables :</strong> <span class='badge bg-success'>#{majorations.join(', ')}</span>"
    end

    message
  end

  def determine_company_size
    case params[:taille_entreprise]
    when "micro"
      "Micro-entreprise (< 10 employés)"
    when "petite"
      "Petite entreprise (< 50 employés)"
    when "moyenne"
      "Moyenne entreprise (< 250 employés)"
    else
      "Taille non déterminée"
    end
  end

  def build_recommendations
    recommendations = []

    # Recommandations en fonction de la taille
    case params[:taille_entreprise]
    when "micro"
      recommendations << "🚀 En tant que micro-entreprise, vous avez accès à des taux préférentiels"
      recommendations << "💡 Priorisez les primes de consultance pour débuter votre développement"
    when "petite"
      recommendations << "📈 Votre petite entreprise peut bénéficier de primes d'investissement importantes"
      recommendations << "👥 Considérez les primes de recrutement et formation"
    when "moyenne"
      recommendations << "🏭 Votre moyenne entreprise a accès à l'ensemble des dispositifs"
      recommendations << "🌱 Les primes de transition économique sont particulièrement adaptées"
    end

    # Recommandations selon le secteur (si spécifié)
    if params[:secteur_activite].present?
      recommendations << "🎯 Votre secteur d'activité ouvre droit à des primes spécialisées"
    end

    recommendations << "📋 Consultez l'outil officiel sur economie-emploi.brussels pour des primes précises"
    recommendations << "⏰ Les demandes doivent être introduites AVANT le début des investissements"
    recommendations
  end

  def build_subsidy_categories
    categories = []

    # Toutes les entreprises éligibles ont accès à ces catégories de base
    categories << {
      name: "Transition économique",
      description: "Consultance et investissements pour la transition sociale/environnementale",
      taux_base: "50%",
      plafond: "15.000€/an (consultance)"
    }

    categories << {
      name: "Investissements",
      description: "Matériels, travaux, immobilier, conformité, sécurisation, accessibilité",
      taux_base: "20-40%",
      plafond: "Variable selon type"
    }

    categories << {
      name: "Recrutement et formation",
      description: "Aides à l'embauche et formation du personnel",
      taux_base: "30-50%",
      plafond: "Variable selon profil"
    }

    categories << {
      name: "Expertise et services externes",
      description: "Consultance générale, études, audits",
      taux_base: "50%",
      plafond: "15.000€/an"
    }

    # Catégories conditionnelles
    if params[:nuisances_chantier] == "oui"
      categories << {
        name: "Nuisances chantier",
        description: "Dédommagement pour les commerçants impactés par des chantiers publics",
        taux_base: "Forfaitaire",
        plafond: "Selon impact"
      }
    end

    # Note: Export suspendu selon le site officiel
    categories << {
      name: "Exportation (suspendues)",
      description: "Primes temporairement suspendues",
      taux_base: "N/A",
      plafond: "N/A"
    }

    categories
  end
end
