# Calculateur de primes post-login pour Bruxelles
# Version complète avec données utilisateur précises - Système RENOLUTION

module Regions
  module Bruxelles
    class BruxellesPostLoginCalculatorService < Regions::BaseService
      def calculate_primes(category_result)
        log_calculation("Début calcul primes post-login Bruxelles", category_result)

        category = category_result[:category]
        user_property = user_property()

        return [] unless user_property

        primes = Prime.where(region: 'bruxelles').order(:ordre_affichage)
        calculate_precise_primes(primes, category, user_property)
      end

      # Méthode publique pour calculer toutes les primes avec inputs utilisateur
      def calculate_all_primes(inputs)
        # Stocker les inputs temporairement
        @params = { user_inputs: inputs }

        # Récupérer la catégorie et propriété utilisateur
        category = @category || determine_user_category()
        user_property = user_property()

        return { prime_results: {}, total_general: 0 } unless user_property

        # Récupérer toutes les primes Bruxelles
        primes = Prime.where(region: 'bruxelles').order(:ordre_affichage)

        results = {}
        total_general = 0

        primes.each do |prime|
          next unless prime_eligible_for_category?(prime, category)

          category_data = prime.valeurs_par_categorie&.[](category)
          next unless category_data

          # Récupérer la saisie utilisateur pour cette prime
          user_input_value = inputs[prime.slug] || inputs[prime.slug.to_s]

          # Calculer le montant selon le type et la saisie utilisateur
          calculated_amount = calculate_amount_with_user_input(
            prime,
            category_data,
            user_property,
            user_input_value
          )

          if calculated_amount > 0
            results[prime.slug] = {
              amount: calculated_amount,
              prime_id: prime.id,
              titre: prime.titre,
              unite: prime.unite
            }
            total_general += calculated_amount
          end
        end

        {
          prime_results: results,
          total_general: total_general
        }
      end

      private

      def determine_user_category
        # Utiliser le BruxellesCategoryService dédié pour le calcul de catégorie
        return @category if @category.present?

        category_service = Regions::Bruxelles::BruxellesCategoryService.new({}, user: @user)
        result = category_service.determine_category

        if result[:category]
          @category = result[:category].to_s
        else
          @category = "2" # Catégorie par défaut
        end

        @category
      end

      def user_inputs
        # Récupérer les saisies utilisateur depuis les paramètres
        @params[:user_inputs] || {}
      end

      def calculate_precise_primes(primes, category, property)
        calculated_primes = []

        primes.each do |prime|
          next unless prime_eligible_for_category?(prime, category)

          precise_amount = calculate_precise_amount(prime, category, property)
          next if precise_amount <= 0

          calculated_primes << {
            prime_id: prime.id,
            slug: prime.slug,
            titre: prime.titre,
            precise_amount: precise_amount,
            unite: prime.unite,
            calculation_type: "precise",
            conditions: prime.condition,
            conseil: prime.conseil,
            document: prime.document,
            category_used: category,
            system: "RENOLUTION",
            property_data: relevant_property_data(property, prime),
            calculation_details: build_calculation_details(prime, category, property, precise_amount)
          }
        end

        calculated_primes
      end

      def prime_eligible_for_category?(prime, category)
        return false unless prime.eligible_categories.present?
        prime.eligible_categories.include?(category)
      end

      def calculate_precise_amount(prime, category, property)
        category_data = prime.valeurs_par_categorie&.[](category)
        return 0 unless category_data

        case category_data["type"]
        when "montant_fixe"
          category_data["montant"] || 0

        when "montant_m2"
          surface = get_relevant_surface(property, prime)
          return 0 unless surface&.positive?

          montant_m2 = category_data["montant_m2"] || 0
          surface_max = category_data["surface_max"]

          effective_surface = surface_max ? [surface, surface_max].min : surface
          effective_surface * montant_m2

        when "montant_unite"
          # Pour les primes à l'unité (escaliers, vélos, sanitaires)
          quantity = get_relevant_quantity(property, prime)
          return 0 unless quantity&.positive?

          montant_unite = category_data["montant_unite"] || 0
          limite = category_data["limite"]

          effective_quantity = limite ? [quantity, limite].min : quantity
          effective_quantity * montant_unite

        when "pourcentage"
          # Primes basées sur le coût des travaux
          montant_travaux = get_work_amount(property, prime)
          return 0 unless montant_travaux&.positive?

          pourcentage = category_data["pourcentage"] || 0
          plafond = category_data["plafond"]

          montant_calcule = (montant_travaux * pourcentage) / 100
          plafond ? [montant_calcule, plafond].min : montant_calcule

        when "montant_m2_bonus"
          # Spécial embellissement façade Bruxelles
          surface = get_relevant_surface(property, prime)
          return 0 unless surface&.positive?

          montant_m2 = (category_data["montant_m2"] || 0) * surface
          bonus_fixe = category_data["bonus_fixe"] || 0
          nb_logements = property.housing_units || 1

          montant_m2 + (bonus_fixe * nb_logements)

        when "forfait_et_plafond_facture"
          # Spécial chauffe-eau/pompe à chaleur
          calculate_forfait_with_invoice_limit(prime, category_data, property)

        else
          0
        end
      end

      def calculate_amount_with_user_input(prime, category_data, property, user_input)
        # Si pas de saisie utilisateur, retourner 0 (l'utilisateur doit interagir)
        return 0 unless user_input.present?

        case category_data["type"]
        when "montant_fixe"
          # 0 ou 1 (Non/Oui)
          user_input.to_i == 1 ? (category_data["montant"] || 0) : 0
        when "montant_m2"
          # Surface saisie * montant au m²
          surface = user_input.to_f
          montant_m2 = category_data["montant_m2"] || 0
          surface_max = category_data["surface_max"]

          effective_surface = surface_max ? [surface, surface_max].min : surface
          effective_surface * montant_m2
        when "montant_unite"
          # Quantité saisie * montant par unité
          quantity = user_input.to_f
          montant_unite = category_data["montant_unite"] || 0
          limite = category_data["limite"]

          effective_quantity = limite ? [quantity, limite].min : quantity
          effective_quantity * montant_unite
        when "pourcentage"
          # Montant des travaux saisi * pourcentage
          montant_travaux = user_input.to_f
          pourcentage = category_data["pourcentage"] || 0
          plafond = category_data["plafond"]

          montant_calcule = (montant_travaux * pourcentage) / 100
          plafond ? [montant_calcule, plafond].min : montant_calcule
        when "montant_m2_bonus"
          # Spécial embellissement façade avec surface saisie
          surface = user_input.to_f
          montant_m2 = category_data["montant_m2"] || 0
          bonus_fixe = category_data["bonus_fixe"] || 0
          nb_logements = property.housing_units || 1

          (surface * montant_m2) + (bonus_fixe * nb_logements)
        when "forfait_et_plafond_facture"
          # Montant facture saisi avec plafond
          montant_facture = user_input.to_f
          plafond = category_data["plafond"] || 0
          forfait = category_data["forfait"] || 0

          [montant_facture, plafond].min + forfait
        else
          0
        end
      end

      def get_relevant_surface(property, prime)
        # Déterminer la surface pertinente selon le type de prime Bruxelles
        case prime.slug
        when /toiture|toit/
          property.roof_surface
        when /facade|mur/
          if prime.slug.include?("avant")
            property.front_facade_surface
          else
            property.wall_surface
          end
        when /sol|plancher/
          property.floor_surface
        when /fenetre|porte/
          property.openings_surface
        when /echafaudage/
          property.scaffolding_surface || property.wall_surface
        else
          property.total_surface || property.liveable_surface
        end
      end

      def get_relevant_quantity(property, prime)
        case prime.slug
        when /escalier/
          property.stairs_count || get_param(:nombre_marches)
        when /velo/
          # Max 2 par logement selon règles Bruxelles
          nb_logements = property.housing_units || 1
          [nb_logements * 2, get_param(:nombre_velos) || 2].min
        when /sanitaire/
          property.bathroom_count || get_param(:nombre_appareils)
        when /controle/
          # Max 2 contrôles par logement
          [(property.housing_units || 1) * 2, 2].min
        else
          1
        end
      end

      def get_work_amount(property, prime)
        # Récupérer le montant des travaux
        work_amount = get_param(:montant_travaux) || get_param("montant_travaux_#{prime.slug}")
        return work_amount.to_f if work_amount

        # Chercher dans les projets/simulations de la propriété
        property.projects&.sum(&:estimated_cost) || 0
      end

      def calculate_forfait_with_invoice_limit(prime, category_data, property)
        # Logique spéciale pour chauffe-eau thermodynamique et pompes à chaleur
        facture_amount = get_param(:montant_facture) || get_param("facture_#{prime.slug}")
        return 0 unless facture_amount&.positive?

        forfait = category_data["forfait"] || 0
        plafond_pourcentage = category_data["plafond_pourcentage"] || 100

        montant_plafonne = facture_amount * (plafond_pourcentage / 100.0)
        [montant_plafonne, forfait].min
      end

      def relevant_property_data(property, prime)
        {
          total_surface: property.total_surface,
          construction_year: property.construction_year,
          property_type: property.property_type,
          heating_type: property.heating_type,
          housing_units: property.housing_units,
          location: property.address
        }
      end

      def build_calculation_details(prime, category, property, amount)
        {
          prime_slug: prime.slug,
          category: category,
          calculation_method: "post_login_precise_renolution",
          amount: amount,
          property_id: property.id,
          system: "RENOLUTION",
          timestamp: Time.current
        }
      end

      public

      def generate_prime_cards(category_result)
        log_calculation("Génération cartes primes Bruxelles", category_result)

        # Pour Bruxelles, les calculs sont gérés côté client par le JavaScript controller
        # qui utilise les données JSON injectées dans la vue
        # Nous retournons une structure minimale pour que la simulation soit créée
        {
          cards: {},
          total: 0,
          category_used: category_result[:category],
          region: 'bruxelles',
          client_side_calculation: true
        }
      end
    end
  end
end
