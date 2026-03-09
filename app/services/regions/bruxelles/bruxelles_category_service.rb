# Service de détermination de catégorie pour la région Bruxelles
# Utilise les données de revenus pour déterminer la catégorie du demandeur

module Regions
  module Bruxelles
    class BruxellesCategoryService < Regions::BaseService
      def determine_category
        log_calculation("Début détermination catégorie Bruxelles", @params)

        return { error: "Service disponible uniquement post-login", eligible: false } unless @is_post_login

        determine_category_post_login
      end

      private

      def determine_category_post_login
        # Récupérer les revenus de l'utilisateur
        return { error: "Revenus non renseignés", eligible: false } unless @user.revenu_demandeur

        # Calculer le revenu total du ménage
        total_household_income = calculate_total_household_income

        # Déterminer la catégorie selon les barèmes Bruxelles
        # Bruxelles utilise généralement 3 catégories basées sur les revenus
        category_code = determine_income_category_bruxelles(total_household_income)

        {
          eligible: true,
          category: category_code,
          color: category_color(category_code),
          details: category_details(category_code),
          total_income: total_household_income,
          family_composition: get_family_composition,
          needs_refinement: false
        }
      end

      def get_property
        property_id = get_param(:property_id)
        return nil unless property_id

        @user.properties.find_by(id: property_id)
      end

      def user_project
        project_id = get_param(:project_id)
        return nil unless project_id

        @user.projects.find_by(id: project_id)
      end

      def calculate_total_household_income
        total = @user.revenu_demandeur.to_f
        total += @user.revenu_conjoint.to_f if @user.revenu_conjoint.present?
        total
      end

      def get_family_composition
        {
          demandeur: @user.revenu_demandeur,
          conjoint: @user.revenu_conjoint,
          personnes_charge: @user.nombre_enfants || 0
        }
      end

      def determine_income_category_bruxelles(total_income)
        # Barèmes simplifiés pour Bruxelles (à adapter selon les vrais seuils)
        # Catégorie C (revenus faibles) : < 45 000 €
        # Catégorie B (revenus moyens) : 45 000 - 100 000 €
        # Catégorie A (revenus élevés) : > 100 000 €

        if total_income < 45_000
          "C"
        elsif total_income < 100_000
          "B"
        else
          "A"
        end
      end

      def category_color(category)
        case category
        when "C"
          "success"  # Vert - catégorie la plus avantageuse
        when "B"
          "warning"  # Jaune - catégorie moyenne
        when "A"
          "secondary"  # Gris - catégorie de base
        else
          "primary"
        end
      end

      def category_details(category)
        case category
        when "C"
          "Catégorie C - Revenus faibles (primes majorées)"
        when "B"
          "Catégorie B - Revenus moyens"
        when "A"
          "Catégorie A - Revenus élevés ou standard"
        else
          "Catégorie #{category}"
        end
      end

      def log_calculation(message, data = nil)
        Rails.logger.info "[BruxellesCategoryService] #{message}"
        Rails.logger.info "[BruxellesCategoryService] Data: #{data.inspect}" if data
      end
    end
  end
end
