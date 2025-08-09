# Service de détermination de catégorie pour la région Flandre
# Utilise exclusivement les données de la base de données post-login
# 4 catégories (1-4) avec des seuils spécifiques à la Flandre

module Regions
  module Flandre
    class FlandreCategoryService < Regions::BaseService
      # Pas de seuil global d'inéligibilité en Flandre - système par catégories

      def determine_category
        log_calculation("Début détermination catégorie Flandre", @params)

        return { error: "Service disponible uniquement post-login", eligible: false } unless @is_post_login

        determine_category_post_login
      end

      private

      def determine_category_post_login
        # Version précise avec données utilisateur réelles
        return { error: "Revenus non renseignés", eligible: false } unless @user.revenu_demandeur

        # Récupérer les données utilisateur et propriété pour critères spéciaux
        property = get_property
        project = user_project

        # Calculer le revenu total du ménage
        total_household_income = calculate_total_household_income

        # Calculer le revenu ajusté avec déductions
        adjusted_income = calculate_adjusted_income(total_household_income)

        # Vérifier les critères spéciaux Flandre d'abord
        special_category = check_special_category_criteria(property, project)
        if special_category
          return {
            eligible: true,
            category: special_category[:category],
            color: category_color(special_category[:category]),
            details: special_category[:reason],
            adjusted_income: adjusted_income,
            total_income: total_household_income,
            deductions: total_household_income - adjusted_income,
            family_composition: get_family_composition,
            needs_refinement: false,
            special_criteria: true
          }
        end

        # Déterminer la catégorie selon les barèmes revenus Flandre
        category_code = determine_income_category_flandre(adjusted_income)

        {
          eligible: true,
          category: category_code,
          color: category_color(category_code),
          details: category_details(category_code),
          adjusted_income: adjusted_income,
          total_income: total_household_income,
          deductions: total_household_income - adjusted_income,
          family_composition: get_family_composition,
          needs_refinement: false
        }
      end

      # Critères spéciaux Flandre basés sur le questionnaire d'éligibilité
      def check_special_category_criteria(property, project)
        # 1. Client protégé → Catégorie 4 (la plus élevée en Flandre)
        if client_protege?
          return { category: "4", reason: "Client protégé - Catégorie maximale (4)" }
        end

        # 2. Appartement ou copropriété → Catégorie 1
        if appartement_ou_copropriete?(property)
          return { category: "1", reason: "Appartement ou copropriété - Catégorie 1" }
        end

        # 3. Immeuble à appartements → Catégorie 1
        if immeuble_appartements?(property)
          return { category: "1", reason: "Immeuble à appartements - Catégorie 1" }
        end

        # 4. Propriétaire d'un autre bien → Catégorie 1
        if proprietaire_autre_bien?
          return { category: "1", reason: "Propriétaire d'un autre bien - Catégorie 1" }
        end

        # 5. Usage non résidentiel → Catégorie 1
        if usage_non_residentiel?(property)
          return { category: "1", reason: "Usage non résidentiel - Catégorie 1" }
        end

        nil # Pas de critère spécial, utiliser les revenus
      end

      # Méthodes de vérification des critères spéciaux
      def client_protege?
        # Vérifier si l'utilisateur est client protégé (champ spécifique ou indicateur)
        @user.respond_to?(:client_protege_flandre) && @user.client_protege_flandre == true
      end

      def appartement_ou_copropriete?(property)
        return false unless property

        # Vérifier type de propriété spécifique Flandre
        appartement_types = %w[appartement appartement_copro vma_appartement]
        property.type_propriete_flandre.in?(appartement_types) ||
        property.type.in?(appartement_types) ||
        property.type&.include?('appartement')
      end

      def immeuble_appartements?(property)
        return false unless property

        immeuble_types = %w[immeuble_appartements multiple_appartements]
        property.type_propriete_flandre.in?(immeuble_types) ||
        property.type.in?(immeuble_types) ||
        property.type&.include?('immeuble')
      end

      def proprietaire_autre_bien?
        # Vérifier si l'utilisateur possède d'autres biens (champ utilisateur)
        @user.respond_to?(:autre_bien_flandre) && @user.autre_bien_flandre == true
      end

      def usage_non_residentiel?(property)
        return false unless property

        # Si habitation_percentage < 100% en Flandre
        return true if property.habitation_percentage.present? && property.habitation_percentage < 100

        # Types non résidentiels
        non_residential_types = %w[commercial industriel mixte bureau]
        property.type_propriete_flandre.in?(non_residential_types) ||
        property.type.in?(non_residential_types)
      end

      # Méthodes de calcul des revenus (adaptées de Wallonie)
      def calculate_total_household_income
        # Revenu du demandeur (obligatoire)
        total = @user.revenu_demandeur || 0

        # Ajouter le revenu du conjoint si marié/cohabitant/couple et si renseigné
        if @user.situation_familiale.in?(%w[marie cohabitant couple]) && @user.revenu_conjoint
          total += @user.revenu_conjoint
        end

        total
      end

      def calculate_adjusted_income(base_income)
        # En Flandre, déduction de 4.320€ par personne à charge supplémentaire
        deductions = 0

        # Déduction enfants à charge
        if @user.nombre_enfants && @user.nombre_enfants > 0
          deductions += @user.nombre_enfants * 4320
        end

        # Déduction personnes âgées à charge (si champ disponible)
        if @user.respond_to?(:personnes_agees_charge) && @user.personnes_agees_charge && @user.personnes_agees_charge > 0
          deductions += @user.personnes_agees_charge * 4320
        end

        [base_income - deductions, 0].max
      end

      def determine_income_category_flandre(adjusted_income)
        # Barèmes Flandre 2025 - 4 catégories (logique inversée : 4 = meilleure)
        # Seuils de base pour personne seule
        situation_familiale = @user.situation_familiale || 'seul'
        nb_charges = (@user.nombre_enfants || 0) + (@user.respond_to?(:personnes_agees_charge) ? (@user.personnes_agees_charge || 0) : 0)

        # Seuils de base selon la situation (adaptés du JS)
        if situation_familiale.in?(%w[seul celibataire])
          if nb_charges > 0
            return "4" if adjusted_income <= 36_340 + (nb_charges - 1) * 4320
            return "3" if adjusted_income <= 59_270 + (nb_charges - 1) * 4320
            return "2" if adjusted_income <= 76_980 + (nb_charges - 1) * 4320
          else
            return "4" if adjusted_income <= 24_230
            return "3" if adjusted_income <= 42_340
            return "2" if adjusted_income <= 53_880
          end
        else # couple
          return "4" if adjusted_income <= 36_340 + nb_charges * 4320
          return "3" if adjusted_income <= 59_270 + nb_charges * 4320
          return "2" if adjusted_income <= 76_980 + nb_charges * 4320
        end

        # Catégorie 1 pour revenus élevés
        "1"
      end

      def get_family_composition
        # Récupérer depuis les données utilisateur réelles
        {
          situation_familiale: @user.situation_familiale,
          nombre_enfants: @user.nombre_enfants || 0,
          revenu_demandeur: @user.revenu_demandeur,
          revenu_conjoint: @user.revenu_conjoint,
          is_couple: @user.situation_familiale.in?(%w[marie cohabitant couple])
        }
      end

      def category_color(category)
        case category
        when "4" then "success"    # Vert - Prime la plus élevée
        when "3" then "info"       # Bleu
        when "2" then "warning"    # Jaune
        when "1" then "secondary"  # Gris - Prime la plus faible
        else "secondary"
        end
      end

      def category_details(category)
        case category
        when "4"
          "Catégorie 4 - Revenus modestes - Primes maximales"
        when "3"
          "Catégorie 3 - Revenus moyens - Primes élevées"
        when "2"
          "Catégorie 2 - Revenus moyens supérieurs - Primes moyennes"
        when "1"
          "Catégorie 1 - Revenus élevés ou critères spéciaux - Primes de base"
        else
          "Catégorie à déterminer"
        end
      end

      def get_property
        # Récupère la propriété associée à la simulation
        property_id = get_param(:property_id)
        Rails.logger.info "🏠 get_property (Flandre Category): property_id param = #{property_id}"
        return nil unless property_id

        property = @user.properties.find_by(id: property_id)
        Rails.logger.info "🏠 get_property (Flandre Category): found property = #{property&.id}, type = '#{property&.type}'"
        property
      end

      def user_project
        # Récupère le projet associé à la simulation en cours
        project_id = get_param(:project_id)
        return nil unless project_id

        @user.projects.find_by(id: project_id)
      end
    end
  end
end
