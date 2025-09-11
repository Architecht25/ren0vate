module Entreprises
  class BruxellesEntreprisesDetailedEligibilityService
    attr_reader :params, :user

    def initialize(user, params = {})
      @user = user
      @params = params
      Rails.logger.info "🔍 Service d'éligibilité détaillée Bruxelles Entreprises initialisé"
    end

    def check_detailed_eligibility
      Rails.logger.info "📋 Début analyse détaillée d'éligibilité entreprise Bruxelles"

      # Récupérer les données depuis la base de données
      property = get_property
      project = get_project

      return error_result("❌ Propriété non trouvée") unless property
      return error_result("❌ Projet non trouvé") unless project

      # Évaluer chaque critère individuellement
      criteria_results = evaluate_all_criteria(property, project)

      # Vérifier si tous les critères sont respectés
      all_eligible = criteria_results.all? { |criterion| criterion[:status] == :success }

      # Construire le résultat détaillé
      {
        eligible: all_eligible,
        criteria: criteria_results,
        summary: build_summary(criteria_results),
        actions: build_action_plan(criteria_results),
        subsidy_info: all_eligible ? build_subsidy_categories : nil
      }
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

    def evaluate_all_criteria(property, project)
      [
        evaluate_location(property),
        evaluate_bce_number(project),
        evaluate_company_size(property),
        evaluate_de_minimis_rule(property),
        evaluate_sector_eligibility(property),
        evaluate_economic_purpose(project),
        evaluate_public_funding_limit(property),
        evaluate_annual_accounts(property),
        evaluate_diversity_plan(property),
        evaluate_application_timing(project)
      ]
    end

    def evaluate_location(property)
      success = property.region&.downcase == 'bruxelles'
      {
        name: "Localisation en Région de Bruxelles-Capitale",
        description: "Le siège d'exploitation doit être situé en Région de Bruxelles-Capitale",
        status: success ? :success : :error,
        value: property.region || "Non spécifiée",
        expected: "Bruxelles",
        action: success ? nil : "Déménager le siège d'exploitation en Région de Bruxelles-Capitale"
      }
    end

    def evaluate_bce_number(project)
      success = project.bce_number.present?
      {
        name: "Numéro d'entreprise BCE",
        description: "Un numéro d'entreprise BCE valide est requis",
        status: success ? :success : :error,
        value: success ? project.bce_number : "Non renseigné",
        expected: "Numéro BCE valide",
        action: success ? nil : "Obtenir un numéro d'entreprise auprès de la Banque Carrefour des Entreprises"
      }
    end

    def evaluate_company_size(property)
      if property.nombre_salaries.nil?
        return {
          name: "Taille d'entreprise (PME)",
          description: "L'entreprise doit être une PME (moins de 250 employés)",
          status: :warning,
          value: "Non spécifié",
          expected: "< 250 employés",
          action: "Préciser le nombre d'employés dans votre profil"
        }
      end

      success = property.nombre_salaries < 250
      company_type = determine_company_size(property.nombre_salaries)

      {
        name: "Taille d'entreprise (PME)",
        description: "L'entreprise doit être une PME (moins de 250 employés)",
        status: success ? :success : :error,
        value: "#{property.nombre_salaries} employés (#{company_type})",
        expected: "< 250 employés",
        action: success ? nil : "Cette aide est réservée aux PME. Vérifier d'autres programmes pour grandes entreprises"
      }
    end

    def evaluate_de_minimis_rule(property)
      # Si regle_minimis est nil, on considère comme conforme
      if property.regle_minimis.nil?
        return {
          name: "Règle de minimis",
          description: "L'entreprise ne doit pas avoir reçu plus de 300.000€ d'aides de minimis sur 3 ans",
          status: :warning,
          value: "Non spécifié",
          expected: "≤ 300.000€ sur 3 ans",
          action: "Vérifier le montant total des aides de minimis reçues sur les 3 dernières années"
        }
      end

      success = property.regle_minimis != true
      {
        name: "Règle de minimis",
        description: "L'entreprise ne doit pas avoir reçu plus de 300.000€ d'aides de minimis sur 3 ans",
        status: success ? :success : :error,
        value: success ? "Conforme (≤ 300.000€)" : "Non conforme (> 300.000€)",
        expected: "≤ 300.000€ sur 3 ans",
        action: success ? nil : "Attendre la période de décompte ou vérifier le calcul des aides de minimis"
      }
    end

    def evaluate_sector_eligibility(property)
      if property.code_nace_1.blank?
        return {
          name: "Secteur d'activité éligible",
          description: "L'activité doit être dans un secteur éligible selon les codes NACE-BEL 2025",
          status: :warning,
          value: "Aucun code NACE renseigné",
          expected: "Code NACE éligible",
          action: "Renseigner le code NACE de votre activité principale"
        }
      end

      eligible_nace_codes = get_eligible_nace_codes
      nace_codes = [property.code_nace_1, property.code_nace_2, property.code_nace_3,
                   property.code_nace_4, property.code_nace_5].compact

      success = nace_codes.any? { |nace_code| eligible_nace_codes.include?(nace_code&.first(2)) }

      {
        name: "Secteur d'activité éligible",
        description: "L'activité doit être dans un secteur éligible selon les codes NACE-BEL 2025",
        status: success ? :success : :error,
        value: nace_codes.join(", "),
        expected: "Code NACE éligible",
        action: success ? nil : "Vérifier si votre activité correspond à un secteur éligible ou diversifier vos activités"
      }
    end

    def evaluate_economic_purpose(project)
      if project.finalite_economique_confirmee.nil?
        return {
          name: "Finalité économique et commerciale",
          description: "L'entreprise doit avoir une finalité économique et commerciale",
          status: :warning,
          value: "Non confirmé",
          expected: "Finalité économique confirmée",
          action: "Confirmer la finalité économique et commerciale de votre entreprise"
        }
      end

      success = project.finalite_economique_confirmee
      {
        name: "Finalité économique et commerciale",
        description: "L'entreprise doit avoir une finalité économique et commerciale",
        status: success ? :success : :error,
        value: success ? "Confirmée" : "Non confirmée",
        expected: "Finalité économique confirmée",
        action: success ? nil : "Confirmer que votre entreprise a bien une finalité économique et commerciale"
      }
    end

    def evaluate_public_funding_limit(property)
      if property.pourcentage_financement_public.nil?
        return {
          name: "Limite de financement public",
          description: "Le financement public total ne peut pas dépasser 75%",
          status: :warning,
          value: "Non spécifié",
          expected: "≤ 75%",
          action: "Préciser le pourcentage de financement public de votre projet"
        }
      end

      success = property.pourcentage_financement_public <= 75.0
      {
        name: "Limite de financement public",
        description: "Le financement public total ne peut pas dépasser 75%",
        status: success ? :success : :error,
        value: "#{property.pourcentage_financement_public}%",
        expected: "≤ 75%",
        action: success ? nil : "Réduire la part de financement public ou augmenter l'autofinancement"
      }
    end

    def evaluate_annual_accounts(property)
      if property.comptes_annuels_conformes.nil?
        return {
          name: "Comptes annuels à jour",
          description: "L'entreprise doit être en ordre avec les obligations de publication",
          status: :warning,
          value: "Non spécifié",
          expected: "Comptes à jour",
          action: "Vérifier le statut de vos obligations de publication auprès de la Banque Nationale"
        }
      end

      success = property.comptes_annuels_conformes
      {
        name: "Comptes annuels à jour",
        description: "L'entreprise doit être en ordre avec les obligations de publication",
        status: success ? :success : :error,
        value: success ? "À jour" : "En retard",
        expected: "Comptes à jour",
        action: success ? nil : "Régulariser le dépôt des comptes annuels auprès de la Banque Nationale"
      }
    end

    def evaluate_diversity_plan(property)
      if property.nombre_salaries.nil? || property.nombre_salaries <= 50
        return {
          name: "Plan de diversité",
          description: "Plan de diversité obligatoire si > 50 travailleurs",
          status: :success,
          value: "Non applicable (≤ 50 employés)",
          expected: "Plan actif si > 50 employés",
          action: nil
        }
      end

      if property.plan_diversite_actif.nil?
        return {
          name: "Plan de diversité",
          description: "Plan de diversité obligatoire si > 50 travailleurs",
          status: :warning,
          value: "Non spécifié (> 50 employés)",
          expected: "Plan de diversité actif",
          action: "Mettre en place un plan de diversité (obligatoire pour les entreprises > 50 employés)"
        }
      end

      success = property.plan_diversite_actif
      {
        name: "Plan de diversité",
        description: "Plan de diversité obligatoire si > 50 travailleurs",
        status: success ? :success : :error,
        value: success ? "Plan actif" : "Pas de plan actif",
        expected: "Plan de diversité actif",
        action: success ? nil : "Mettre en place un plan de diversité (obligatoire pour les entreprises > 50 employés)"
      }
    end

    def evaluate_application_timing(project)
      if project.demande_avant_debut.nil? && project.date_début.blank?
        return {
          name: "Demande avant début",
          description: "La demande doit être introduite AVANT le début du projet",
          status: :warning,
          value: "Non spécifié",
          expected: "Demande avant début",
          action: "Confirmer que la demande sera faite avant le début du projet"
        }
      end

      # Vérification basée sur demande_avant_debut si disponible
      if project.demande_avant_debut.present?
        success = project.demande_avant_debut
        return {
          name: "Demande avant début",
          description: "La demande doit être introduite AVANT le début du projet",
          status: success ? :success : :error,
          value: success ? "Confirmé" : "Projet déjà commencé",
          expected: "Demande avant début",
          action: success ? nil : "Cette condition ne peut plus être remplie pour ce projet"
        }
      end

      # Vérification basée sur la date de début
      if project.date_début.present?
        success = project.date_début > Date.current
        return {
          name: "Demande avant début",
          description: "La demande doit être introduite AVANT le début du projet",
          status: success ? :success : :error,
          value: success ? "Projet non commencé" : "Projet déjà commencé",
          expected: "Demande avant début",
          action: success ? nil : "Cette condition ne peut plus être remplie pour ce projet"
        }
      end

      # Par défaut, si aucune info disponible
      {
        name: "Demande avant début",
        description: "La demande doit être introduite AVANT le début du projet",
        status: :warning,
        value: "À confirmer",
        expected: "Demande avant début",
        action: "S'assurer de faire la demande avant de commencer le projet"
      }
    end

    def build_summary(criteria_results)
      success_count = criteria_results.count { |c| c[:status] == :success }
      warning_count = criteria_results.count { |c| c[:status] == :warning }
      error_count = criteria_results.count { |c| c[:status] == :error }

      total = criteria_results.count
      success_percentage = (success_count.to_f / total * 100).round

      if error_count == 0 && warning_count == 0
        "✅ Toutes les conditions sont remplies ! Votre entreprise est éligible."
      elsif error_count == 0
        "⚠️ #{success_count}/#{total} conditions validées (#{warning_count} à préciser). Éligibilité probable."
      else
        "❌ #{error_count} condition(s) non remplie(s). Actions correctives nécessaires."
      end
    end

    def build_action_plan(criteria_results)
      actions = criteria_results
        .select { |c| c[:action].present? }
        .map { |c| { criterion: c[:name], action: c[:action], priority: priority_for_status(c[:status]) } }
        .sort_by { |a| a[:priority] }

      actions
    end

    def priority_for_status(status)
      case status
      when :error then 1    # Priorité haute
      when :warning then 2  # Priorité moyenne
      when :success then 3  # Pas de priorité (pas d'action)
      end
    end

    def determine_company_size(nombre_salaries)
      case nombre_salaries
      when 0...10
        "Micro-entreprise"
      when 10...50
        "Petite entreprise"
      when 50...250
        "Moyenne entreprise"
      else
        "Grande entreprise"
      end
    end

    def get_eligible_nace_codes
      # Codes NACE éligibles pour les aides de Bruxelles Economie et Emploi
      [
        '10', '11', '12', '13', '14', '15', '16', '17', '18', '19',
        '20', '21', '22', '23', '24', '25', '26', '27', '28', '29',
        '30', '31', '32', '33', '41', '42', '43', '45', '46', '47',
        '49', '50', '51', '52', '53', '55', '56', '58', '59', '60',
        '61', '62', '63', '66', '68', '69', '70', '71', '72', '73',
        '74', '75', '77', '78', '79', '80', '81', '82', '85', '86',
        '87', '88', '90', '91', '92', '93', '94', '95', '96'
      ]
    end

    def build_subsidy_categories
      [
        {
          name: "Transition Économique",
          description: "Consultance, investissements verts, mobilité",
          max_amount: "15.000€ par an"
        },
        {
          name: "Investissements Matériels",
          description: "Matériel, travaux, conformité, sécurisation",
          max_amount: "500.000€ selon type"
        },
        {
          name: "Accessibilité",
          description: "Aménagements pour personnes à mobilité réduite",
          max_amount: "80.000€"
        }
      ]
    end

    def error_result(message)
      {
        eligible: false,
        error: message,
        criteria: [],
        summary: message,
        actions: []
      }
    end
  end
end
