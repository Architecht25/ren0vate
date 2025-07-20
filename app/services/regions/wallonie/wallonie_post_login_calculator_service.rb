# Calculateur de primes post-login pour la Wallonie
# Version complète avec données utilisateur précises

module Regions
  module Wallonie
    class WalloniePostLoginCalculatorService < Regions::BaseService
      def calculate_primes(category_result)
        log_calculation("Début calcul primes post-login Wallonie", category_result)

        category = category_result[:category]
        user_property = user_property()

        return [] unless user_property

        primes = Prime.where(region: 'wallonie').order(:ordre_affichage)
        calculate_precise_primes(primes, category, user_property)
      end

      private

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
            category_used: category,
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

        when "pourcentage"
          # Nécessite le montant des travaux (depuis les paramètres ou propriété)
          montant_travaux = get_work_amount(property, prime)
          return 0 unless montant_travaux&.positive?

          pourcentage = category_data["pourcentage"] || 0
          plafond = category_data["plafond"]

          montant_calcule = (montant_travaux * pourcentage) / 100
          plafond ? [montant_calcule, plafond].min : montant_calcule

        when "montant_variable"
          # Basé sur des caractéristiques spécifiques
          calculate_variable_amount(prime, category_data, property)

        else
          0
        end
      end

      def get_relevant_surface(property, prime)
        # Déterminer la surface pertinente selon le type de prime
        case prime.slug
        when /toiture|toit/
          property.roof_surface
        when /facade|mur/
          property.wall_surface
        when /sol|plancher/
          property.floor_surface
        else
          property.total_surface || property.liveable_surface
        end
      end

      def get_work_amount(property, prime)
        # Récupérer le montant des travaux depuis les projets/simulations
        # ou depuis les paramètres du calcul
        work_amount = get_param(:montant_travaux) || get_param("montant_travaux_#{prime.slug}")
        return work_amount.to_f if work_amount

        # Sinon chercher dans les projets de la propriété
        property.projects&.sum(&:estimated_cost) || 0
      end

      def calculate_variable_amount(prime, category_data, property)
        # Logique spécifique selon le type de prime
        case prime.slug
        when /chaudiere|chauffage/
          calculate_heating_amount(category_data, property)
        when /ventilation/
          calculate_ventilation_amount(category_data, property)
        else
          category_data["montant_defaut"] || 0
        end
      end

      def calculate_heating_amount(category_data, property)
        # Exemple de calcul pour chaudière selon puissance
        puissance = property.heating_power || get_param(:puissance_chaudiere)
        return 0 unless puissance

        if puissance <= 100
          category_data["montant_jusque_100kw"] || 0
        else
          category_data["montant_plus_100kw"] || 0
        end
      end

      def calculate_ventilation_amount(category_data, property)
        # Calcul selon le nombre de logements
        nb_logements = property.housing_units || 1
        montant_par_logement = category_data["montant_par_logement"] || 0

        nb_logements * montant_par_logement
      end

      def relevant_property_data(property, prime)
        {
          total_surface: property.total_surface,
          construction_year: property.construction_year,
          property_type: property.property_type,
          heating_type: property.heating_type
        }
      end

      def build_calculation_details(prime, category, property, amount)
        {
          prime_slug: prime.slug,
          category: category,
          calculation_method: "post_login_precise",
          amount: amount,
          timestamp: Time.current
        }
      end
    end
  end
end
