# Service de détermination de catégorie pour la région Wallonie
# Migré et amélioré depuis wallonie_category_service.rb

module Regions
  module Wallonie
    class WallonieCategoryService < Regions::BaseService
      def determine_category
        log_calculation("Début détermination catégorie Wallonie", @params)

        if @is_post_login
          determine_category_post_login
        else
          determine_category_pre_login
        end
      end

      private

      def determine_category_pre_login
        # Version basée sur le revenu imposable fourni
        revenu_imposable = get_param(:revenu_imposable)

        if revenu_imposable
          # Utiliser la même logique que post-login mais avec composition familiale simplifiée
          categories = Category.wallonie.order(:seuil_seul)
          family_composition = build_family_composition_from_params
          matching_category = find_matching_category(categories, revenu_imposable, family_composition)

          {
            category: matching_category.code.sub('wallonie_', '').upcase,
            color: category_color(matching_category.code.sub('wallonie_', '').upcase),
            details: matching_category.description,
            needs_refinement: false
          }
        else
          # Fallback sur l'ancienne logique si pas de revenu imposable
          revenu_tranche = get_param(:revenu_net) || get_param(:revenu_tranche)

          category = case revenu_tranche
                     when "r1" then "R1"
                     when "r2" then "R2"
                     when "r3" then "R3"
                     when "r4" then "R4"
                     when "r5" then "R5"
                     else
                       # Si pas de tranche précise, estimer selon le booléen revenus
                       get_param(:revenus) == "non" ? "R1-R4" : "R5"
                     end

          {
            category: category,
            color: category_color(category),
            details: category_details(category),
            needs_refinement: category.include?("-")
          }
        end
      end

      def determine_category_post_login
        # Version précise avec données utilisateur réelles
        return { error: "Revenus non renseignés" } unless @user.household_income

        # Récupérer les catégories Wallonie depuis la base
        categories = Category.wallonie.order(:seuil_seul)

        family_composition = get_family_composition
        matching_category = find_matching_category(categories, @user.household_income, family_composition)

        {
          category: matching_category.code,
          color: category_color(matching_category.code),
          details: matching_category.description,
          family_composition: family_composition,
          exact_income: @user.household_income,
          needs_refinement: false,
          category_object: matching_category
        }
      end

      def get_family_composition
        # Récupérer depuis les données utilisateur ou les paramètres
        is_couple = %w[married cohabiting].include?(@user&.marital_status || get_param(:statut_familial))
        children = @user&.children_count || get_param(:enfants_charge).to_i
        elderly = @user&.elderly_dependents || get_param(:personnes_agees_charge).to_i

        {
          is_couple: is_couple,
          children_count: children,
          elderly_dependents: elderly,
          statut_familial: @user&.marital_status || get_param(:statut_familial)
        }
      end

      def build_family_composition_from_params
        # Construire la composition familiale à partir des paramètres pré-login
        situation = get_param(:situation_familiale)
        children = get_param(:nombre_personnes_fiscalement_a_charge) || 0

        {
          is_couple: situation != "seul",
          children_count: children.to_i,
          elderly_dependents: 0, # Pas d'info dans les paramètres pré-login
          statut_familial: situation
        }
      end

      def find_matching_category(categories, income, family_composition)
        # Trouver la catégorie appropriée selon les revenus
        categories.each do |category|
          if category.eligible_for_income?(income, family_composition)
            return category
          end
        end

        # Si aucune catégorie trouvée, retourner R5 par défaut
        categories.find { |c| c.code == "wallonie_r5" } || categories.last
      end

      def category_color(category)
        case category
        when "R1" then "success"    # Vert - Prime la plus élevée
        when "R2" then "info"       # Bleu
        when "R3" then "warning"    # Jaune
        when "R4" then "secondary"  # Gris
        when "R5" then "danger"     # Rouge - Prime la plus faible
        when "R1-R4" then "warning" # Jaune pour les estimations
        else "secondary"
        end
      end

      def category_details(category)
        case category
        when "R1"
          "Revenus très modestes - Primes maximales"
        when "R2"
          "Revenus modestes - Primes élevées"
        when "R3"
          "Revenus moyens - Primes moyennes"
        when "R4"
          "Revenus moyens supérieurs - Primes réduites"
        when "R5"
          "Revenus supérieurs - Primes minimales"
        when "R1-R4"
          "Catégorie à affiner selon revenus exacts"
        else
          "Catégorie à déterminer"
        end
      end
    end
  end
end
