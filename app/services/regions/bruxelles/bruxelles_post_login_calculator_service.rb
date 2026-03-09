# Calculateur de primes post-login pour Bruxelles-Capitale
# Version complète avec données utilisateur précises

module Regions
  module Bruxelles
    class BruxellesPostLoginCalculatorService < Regions::BaseService
      def calculate_primes(category_result)
        log_calculation("Début calcul primes post-login Bruxelles", category_result)

        category = category_result[:category]
        user_property = get_property

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
        user_property = get_property

        return { prime_results: {}, total_general: 0 } unless user_property

        # Récupérer toutes les primes Bruxelles
        primes = Prime.where(region: 'bruxelles').order(:ordre_affichage)

        results = {}
        total_general = 0

        primes.each do |prime|
          next unless prime_eligible_for_category?(prime, category)

          # Récupérer les données de catégorie
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

      def calculate_precise_amount(prime, category, property)
        category_data = prime.valeurs_par_categorie&.[](category)
        return 0 unless category_data

        case prime.type_calcul
        when 'forfait'
          category_data['montant'].to_f
        when 'surface'
          surface = property.surface_habitable || 0
          montant_m2 = category_data['montant'].to_f
          plafond = category_data['plafond'].to_f
          calculated = surface * montant_m2
          plafond > 0 ? [calculated, plafond].min : calculated
        when 'pourcentage'
          # Pour les calculs en pourcentage, on ne peut pas calculer sans le montant des travaux
          0
        else
          0
        end
      end

      def calculate_amount_with_user_input(prime, category_data, property, user_input)
        case prime.type_calcul
        when 'forfait'
          category_data['montant'].to_f
        when 'surface'
          surface = user_input.to_f > 0 ? user_input.to_f : (property.surface_habitable || 0)
          montant_m2 = category_data['montant'].to_f
          plafond = category_data['plafond'].to_f
          calculated = surface * montant_m2
          plafond > 0 ? [calculated, plafond].min : calculated
        when 'pourcentage'
          if user_input.to_f > 0
            montant_travaux = user_input.to_f
            pourcentage = category_data['montant'].to_f / 100.0
            plafond = category_data['plafond'].to_f
            calculated = montant_travaux * pourcentage
            plafond > 0 ? [calculated, plafond].min : calculated
          else
            0
          end
        when 'unite'
          if user_input.to_f > 0
            quantite = user_input.to_f
            montant_unite = category_data['montant'].to_f
            plafond = category_data['plafond'].to_f
            calculated = quantite * montant_unite
            plafond > 0 ? [calculated, plafond].min : calculated
          else
            0
          end
        else
          0
        end
      end

      def prime_eligible_for_category?(prime, category)
        return true unless prime.valeurs_par_categorie

        prime.valeurs_par_categorie.key?(category)
      end

      def relevant_property_data(property, prime)
        {
          surface_habitable: property.surface_habitable,
          annee_construction: property.annee_construction,
          type_bien: property.type_bien_bruxelles,
          profil_demandeur: property.profil_demandeur
        }
      end

      def build_calculation_details(prime, category, property, amount)
        category_data = prime.valeurs_par_categorie&.[](category)
        {
          type_calcul: prime.type_calcul,
          category: category,
          montant_base: category_data&.[]('montant'),
          plafond: category_data&.[]('plafond'),
          montant_calcule: amount,
          property_surface: property.surface_habitable
        }
      end

      def determine_user_category
        category_service = BruxellesCategoryService.new(@params, user: @user)
        result = category_service.determine_category
        result[:category]
      end

      def log_calculation(message, data = nil)
        Rails.logger.info "[BruxellesPostLoginCalculatorService] #{message}"
        Rails.logger.info "[BruxellesPostLoginCalculatorService] Data: #{data.inspect}" if data
      end
    end
  end
end
