# Service de détermination de catégorie pour la région Bruxelles
# Basé sur le système RENOLUTION à 3 catégories

module Regions
  module Bruxelles
    class BruxellesCategoryService < Regions::BaseService
      def determine_category
        log_calculation("Début détermination catégorie Bruxelles", @params)

        if @is_post_login
          determine_category_post_login
        else
          determine_category_pre_login
        end
      end

      private

      def determine_category_pre_login
        # Version simplifiée basée sur autodéclaration
        category = estimate_category_from_params

        {
          category: category,
          color: category_color(category),
          details: category_details(category),
          needs_refinement: category.include?("-"),
          system: "RENOLUTION"
        }
      end

      def determine_category_post_login
        # Version précise avec données utilisateur réelles
        return { error: "Revenus non renseignés" } unless @user.household_income

        family_composition = get_family_composition
        category = calculate_category_from_income(@user.household_income, family_composition)

        {
          category: category,
          color: category_color(category),
          details: category_details(category),
          family_composition: family_composition,
          exact_income: @user.household_income,
          needs_refinement: false,
          system: "RENOLUTION",
          thresholds_used: calculate_thresholds(family_composition)
        }
      end

      def estimate_category_from_params
        # Estimation basée sur les paramètres fournis
        if get_param(:revenus_bas) == "oui"
          "bruxelles_cat1"
        elsif get_param(:revenus_moyens) == "oui"
          "bruxelles_cat2"
        elsif get_param(:revenus_eleves) == "oui"
          "bruxelles_cat3"
        elsif get_param(:revenus_precis)
          # Si montant précis fourni
          income = get_param(:revenus_precis).to_f
          return "bruxelles_cat1-cat3" if income <= 0

          # Estimation rapide avec ménage type (2 personnes)
          thresholds = calculate_thresholds({ family_size: 2 })
          return "bruxelles_cat1" if income <= thresholds[:cat1]
          return "bruxelles_cat2" if income <= thresholds[:cat2]
          "bruxelles_cat3"
        else
          # Pas assez d'infos pour estimer
          "bruxelles_cat1-cat3"
        end
      end

      def get_family_composition
        {
          family_size: calculate_family_size,
          marital_status: @user&.marital_status || get_param(:statut_familial),
          children_count: @user&.children_count || get_param(:enfants_charge).to_i,
          elderly_dependents: @user&.elderly_dependents || get_param(:personnes_agees_charge).to_i
        }
      end

      def calculate_family_size
        base_size = 1

        # Ajouter conjoint si applicable
        if @user&.marital_status&.in?(%w[married cohabiting]) ||
           get_param(:statut_familial)&.in?(%w[married cohabiting])
          base_size += 1
        end

        # Ajouter personnes à charge
        children = @user&.children_count || get_param(:enfants_charge).to_i
        elderly = @user&.elderly_dependents || get_param(:personnes_agees_charge).to_i

        base_size + children + elderly
      end

      def calculate_category_from_income(income, family_composition)
        thresholds = calculate_thresholds(family_composition)

        return "bruxelles_cat1" if income <= thresholds[:cat1]
        return "bruxelles_cat2" if income <= thresholds[:cat2]
        "bruxelles_cat3"
      end

      def calculate_thresholds(family_composition)
        family_size = family_composition[:family_size] || 2

        # Seuils de base Bruxelles RENOLUTION 2024
        # (À ajuster selon les vrais barèmes)
        base_thresholds = {
          cat1: 27_000,  # Revenus modestes
          cat2: 48_000   # Revenus moyens
        }

        # Majoration par personne supplémentaire au-delà de 1
        additional_per_person = 5_200
        bonus = [family_size - 1, 0].max * additional_per_person

        {
          cat1: base_thresholds[:cat1] + bonus,
          cat2: base_thresholds[:cat2] + bonus
        }
      end

      def category_color(category)
        case category
        when "bruxelles_cat1"
          "success"    # Vert - Primes les plus élevées
        when "bruxelles_cat2"
          "warning"    # Jaune - Primes moyennes
        when "bruxelles_cat3"
          "danger"     # Rouge - Primes les plus faibles
        when /cat1-cat3/
          "info"       # Bleu pour les estimations
        else
          "secondary"
        end
      end

      def category_details(category)
        case category
        when "bruxelles_cat1"
          "Revenus modestes - Primes RENOLUTION maximales"
        when "bruxelles_cat2"
          "Revenus moyens - Primes RENOLUTION moyennes"
        when "bruxelles_cat3"
          "Revenus élevés - Primes RENOLUTION de base"
        when /cat1-cat3/
          "Catégorie à affiner selon revenus précis"
        else
          "Catégorie à déterminer"
        end
      end
    end
  end
end
