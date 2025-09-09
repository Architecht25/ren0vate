module Entreprises
  class BruxellesEntreprisesEligibilityService
    attr_reader :params, :user

    def initialize(user, params = {})
      @user = user
      @params = params
      Rails.logger.info "🏢 Service d'éligibilité Bruxelles Entreprises initialisé"
    end

    def check_eligibility
      Rails.logger.info "🎯 Début vérification éligibilité entreprise Bruxelles"

      # Récupérer les données depuis la base de données
      property = get_property
      project = get_project

      return ineligible("❌ Propriété non trouvée") unless property
      return ineligible("❌ Projet non trouvé") unless project

      # Vérifications automatiques basées sur les données
      return ineligible("❌ Le siège d'exploitation doit être situé en Région de Bruxelles-Capitale") unless property_in_bruxelles?(property)
      return ineligible("❌ Un numéro d'entreprise BCE valide est requis") unless project.bce_number.present?
      return ineligible("❌ L'entreprise doit être une PME (moins de 250 employés)") unless is_pme?(property)
      return ineligible("❌ L'entreprise ne peut pas avoir reçu plus de 300.000€ d'aides de minimis sur 3 ans") if violates_de_minimis_rule?(property)
      return ineligible("❌ L'activité de l'entreprise doit être dans un secteur éligible") unless eligible_sector?(property)

      # Si toutes les vérifications passent, l'entreprise est éligible
      eligible_result = {
        eligible: true,
        message: build_success_message(project),
        recommendations: build_recommendations(project),
        subsidy_categories: build_subsidy_categories
      }

      Rails.logger.info "✅ Entreprise éligible: #{eligible_result}"
      eligible_result
    end

    private

    def get_property
      return nil unless @params[:property_id] && @user
      @user.properties.find_by(id: @params[:property_id])
    end

    def get_project
      return nil unless @params[:project_id] && @user
      @user.projects.find_by(id: @params[:project_id])
    end

    def property_in_bruxelles?(property)
      property.region&.downcase == 'bruxelles'
    end

    def is_pme?(property)
      # Une PME a moins de 250 employés
      return true if property.nombre_salaries.nil? # Si pas spécifié, on considère comme éligible
      property.nombre_salaries < 250
    end

    def violates_de_minimis_rule?(property)
      # true si l'entreprise a reçu plus de 300.000€ d'aides de minimis (donc non éligible)
      # false si elle n'a pas dépassé la limite (donc éligible)
      property.regle_minimis == true
    end

    def eligible_sector?(property)
      # Pour l'instant, on accepte tous les secteurs
      # TODO: Implémenter la logique des secteurs éligibles basée sur les codes NACE
      return true if property.code_nace_1.blank?

      # Liste des secteurs éligibles (codes NACE principaux)
      eligible_nace_codes = get_eligible_nace_codes

      # Vérifier si au moins un des codes NACE de l'entreprise est éligible
      [property.code_nace_1, property.code_nace_2, property.code_nace_3,
       property.code_nace_4, property.code_nace_5].compact.any? do |nace_code|
        eligible_nace_codes.include?(nace_code&.first(2)) # Vérification sur les 2 premiers chiffres
      end
    end

    def get_eligible_nace_codes
      # Codes NACE éligibles pour les aides de Bruxelles Economie et Emploi
      # Basé sur la documentation officielle
      [
        # Secteur manufacturier
        '10', '11', '12', '13', '14', '15', '16', '17', '18', '19',
        '20', '21', '22', '23', '24', '25', '26', '27', '28', '29',
        '30', '31', '32', '33',
        # Construction
        '41', '42', '43',
        # Commerce et réparation
        '45', '46', '47',
        # Transport et entreposage
        '49', '50', '51', '52', '53',
        # Hébergement et restauration
        '55', '56',
        # Information et communication
        '58', '59', '60', '61', '62', '63',
        # Activités financières et d'assurance (partiellement)
        '66',
        # Activités immobilières (partiellement)
        '68',
        # Activités spécialisées, scientifiques et techniques
        '69', '70', '71', '72', '73', '74', '75',
        # Activités de services administratifs et de soutien
        '77', '78', '79', '80', '81', '82',
        # Enseignement (privé)
        '85',
        # Santé humaine et action sociale (privé)
        '86', '87', '88',
        # Arts, spectacles et activités récréatives
        '90', '91', '92', '93',
        # Autres activités de services
        '94', '95', '96'
      ]
    end

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

    def build_success_message(project)
      property = get_property
      message = "✅ Votre entreprise est éligible aux aides de Bruxelles Economie et Emploi !"
      message += "<br><br><strong>Projet :</strong> #{project.nom}"
      message += "<br><strong>Numéro BCE :</strong> #{project.bce_number}" if project.bce_number.present?

      if property&.nombre_salaries.present?
        taille_entreprise = determine_company_size(property.nombre_salaries)
        message += "<br><strong>Taille d'entreprise :</strong> <span class='badge bg-info'>#{taille_entreprise}</span>"
      end

      message
    end

    def determine_company_size(nombre_salaries)
      case nombre_salaries
      when 0...10
        "Micro-entreprise (< 10 employés)"
      when 10...50
        "Petite entreprise (10-49 employés)"
      when 50...250
        "Moyenne entreprise (50-249 employés)"
      else
        "Grande entreprise (≥ 250 employés)"
      end
    end

    def build_recommendations(project)
      recommendations = []
      recommendations << "🏢 Votre entreprise répond aux critères d'éligibilité de base"
      recommendations << "📋 Assurez-vous que votre entreprise est bien inscrite à la BCE"
      recommendations << "💼 Les montants des primes correspondent à la grille tarifaire entreprise"
      recommendations << "📅 Les demandes doivent être introduites AVANT le début des investissements"
      recommendations << "🌐 Consultez economie-emploi.brussels pour les conditions détaillées"
      recommendations
    end

    def build_subsidy_categories
      [
        {
          name: "Aides aux investissements productifs",
          description: "Primes pour équipements et travaux productifs",
          max_amount: "200.000€",
          rate: "20% (PME) - 35% (majorations)"
        },
        {
          name: "Aides à l'innovation",
          description: "Soutien aux projets innovants",
          max_amount: "300.000€",
          rate: "Variable selon le type"
        },
        {
          name: "Aides à l'environnement",
          description: "Primes pour investissements environnementaux",
          max_amount: "150.000€",
          rate: "30-50%"
        }
      ]
    end
  end
end
