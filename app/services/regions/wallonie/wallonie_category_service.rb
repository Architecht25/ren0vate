# Service de détermination de catégorie pour la région Wallonie
# Utilise exclusivement les données de la base de données post-login
# 5 catégories (R1-R5) avec seuil d'inéligibilité à 114.400€

module Regions
  module Wallonie
    class WallonieCategoryService < Regions::BaseService
      ELIGIBILITY_THRESHOLD = 114_400 # Seuil maximum d'éligibilité

      def determine_category
        log_calculation("Début détermination catégorie Wallonie", @params)

        return { error: "Service disponible uniquement post-login", eligible: false } unless @is_post_login

        determine_category_post_login
      end

      private

      def determine_category_post_login
        # Version précise avec données utilisateur réelles

        # Vérification spéciale pour les syndics : catégorie R5 automatique
        profile_type = get_param(:profile_type) || get_param(:user_type)
        if profile_type == "syndic"
          return {
            eligible: true,
            category: "R5",
            color: category_color("R5"),
            details: "Syndic de copropriété - Catégorie R5 appliquée automatiquement",
            adjusted_income: nil,
            total_income: nil,
            deductions: 0,
            family_composition: { profile_type: "syndic" },
            needs_refinement: false
          }
        end

        return { error: "Revenus non renseignés", eligible: false } unless @user.revenu_demandeur

        # Calculer le revenu total du ménage
        total_household_income = calculate_total_household_income

        # Calculer le revenu ajusté avec déductions
        adjusted_income = calculate_adjusted_income(total_household_income)

        # Vérifier le seuil d'éligibilité
        if adjusted_income > ELIGIBILITY_THRESHOLD
          return {
            eligible: false,
            message: "Revenus trop élevés (#{adjusted_income}€ > #{ELIGIBILITY_THRESHOLD}€)",
            adjusted_income: adjusted_income,
            total_income: total_household_income
          }
        end

        # Déterminer la catégorie selon les barèmes Wallonie
        category_code = determine_income_category(adjusted_income)

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

      # Méthodes de calcul des revenus
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
        # Déduction de 5.000€ par enfant à charge, grossesse en cours ou personne > 60 ans
        deductions = 0

        # Déduction enfants à charge
        if @user.nombre_enfants && @user.nombre_enfants > 0
          deductions += @user.nombre_enfants * 5000
          Rails.logger.info "💰 Déduction enfants: #{@user.nombre_enfants} × 5.000€ = #{@user.nombre_enfants * 5000}€"
        end

        # Déduction personnes de 60 ans et plus
        if @user.respond_to?(:personnes_60_ans_et_plus) && @user.personnes_60_ans_et_plus && @user.personnes_60_ans_et_plus > 0
          deductions += @user.personnes_60_ans_et_plus * 5000
          Rails.logger.info "👴 Déduction personnes 60+: #{@user.personnes_60_ans_et_plus} × 5.000€ = #{@user.personnes_60_ans_et_plus * 5000}€"
        end

        # Déduction femme enceinte
        if @user.respond_to?(:femme_enceinte) && @user.femme_enceinte == true
          deductions += 5000
          Rails.logger.info "🤰 Déduction femme enceinte: 5.000€"
        end

        Rails.logger.info "📊 Total déductions: [masqué]€ (calcul catégorie revenus)"

        [base_income - deductions, 0].max
      end

      def determine_income_category(adjusted_income)
        # Barèmes Wallonie 2025 (revenus imposables après déductions) - 5 catégories seulement
        # Seuils harmonisés avec db/seeds/wallonie/categories.rb
        return "R1" if adjusted_income <= 25_400
        return "R2" if adjusted_income <= 36_200
        return "R3" if adjusted_income <= 51_800
        return "R4" if adjusted_income <= 79_000
        return "R5" if adjusted_income <= 114_400

        # Si on arrive ici, c'est une erreur car l'éligibilité devrait être vérifiée en amont
        # (check dans determine_category_post_login ligne 49)
        "R5" # Fallback sur R5 par sécurité
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
        when "R1" then "success"    # Vert - Prime la plus élevée
        when "R2" then "info"       # Bleu
        when "R3" then "warning"    # Jaune
        when "R4" then "secondary"  # Gris
        when "R5" then "danger"     # Rouge - Prime la plus faible
        else "secondary"
        end
      end

      def category_details(category)
        case category
        when "R1"
          "Revenus très modestes (≤ 25.400€) - Primes maximales"
        when "R2"
          "Revenus modestes (25.401€ - 36.200€) - Primes élevées"
        when "R3"
          "Revenus moyens (36.201€ - 51.800€) - Primes moyennes"
        when "R4"
          "Revenus moyens supérieurs (51.801€ - 79.000€) - Primes réduites"
        when "R5"
          "Revenus supérieurs (79.001€ - 114.400€) - Primes minimales"
        else
          "Catégorie à déterminer"
        end
      end
    end
  end
end
