# Calculateur de primes pré-login pour Bruxelles
# Version simplifiée pour utilisateurs non connectés - Système RENOLUTION

module Regions
  module Bruxelles
    class BruxellesPreLoginCalculatorService < Regions::BaseService
      def calculate_primes(category_result)
        log_calculation("Début calcul primes pré-login Bruxelles", category_result)

        category = category_result[:category]
        primes = Prime.where(region: 'bruxelles').order(:ordre_affichage)

        calculate_estimated_primes(primes, category)
      end

      private

      def calculate_estimated_primes(primes, category)
        calculated_primes = []

        primes.each do |prime|
          next unless prime_eligible_for_category?(prime, category)

          estimated_amount = estimate_prime_amount(prime, category)
          next if estimated_amount <= 0

          calculated_primes << {
            prime_id: prime.id,
            slug: prime.slug,
            titre: prime.titre,
            estimated_amount: estimated_amount,
            unite: prime.unite,
            calculation_type: "estimation",
            conditions: prime.condition,
            conseil: prime.conseil,
            category_used: category,
            system: "RENOLUTION",
            disclaimer: "Estimation RENOLUTION. Montant exact après connexion et audit énergétique."
          }
        end

        calculated_primes
      end

      def prime_eligible_for_category?(prime, category)
        return false unless prime.eligible_categories.present?

        # Gérer les catégories multiples comme "bruxelles_cat1-cat3"
        if category.include?("-")
          expanded_categories = expand_category_range(category)
          expanded_categories.any? { |cat| prime.eligible_categories.include?(cat) }
        else
          prime.eligible_categories.include?(category)
        end
      end

      def expand_category_range(category_range)
        # "bruxelles_cat1-cat3" devient ["bruxelles_cat1", "bruxelles_cat2", "bruxelles_cat3"]
        if category_range == "bruxelles_cat1-cat3"
          %w[bruxelles_cat1 bruxelles_cat2 bruxelles_cat3]
        else
          [category_range]
        end
      end

      def estimate_prime_amount(prime, category)
        # Utiliser des valeurs moyennes pour l'estimation Bruxelles
        category_data = get_category_data(prime, category)
        return 0 unless category_data

        case category_data["type"]
        when "montant_fixe"
          category_data["montant"] || 0

        when "montant_m2"
          # Estimation avec surface moyenne selon le type de prime
          surface_moyenne = estimate_average_surface(prime)
          (category_data["montant_m2"] || 0) * surface_moyenne

        when "montant_unite"
          # Pour les primes à l'unité (escaliers, vélos, etc.)
          unite_moyenne = estimate_average_units(prime)
          (category_data["montant_unite"] || 0) * unite_moyenne

        when "pourcentage"
          # Estimation avec montant moyen de travaux
          montant_travaux_moyen = estimate_average_work_cost(prime)
          pourcentage = category_data["pourcentage"] || 0
          plafond = category_data["plafond"]

          montant_calcule = (montant_travaux_moyen * pourcentage) / 100
          plafond ? [montant_calcule, plafond].min : montant_calcule

        when "montant_m2_bonus"
          # Spécifique à certaines primes Bruxelles (embellissement façade)
          surface_moyenne = estimate_average_surface(prime)
          montant_m2 = (category_data["montant_m2"] || 0) * surface_moyenne
          bonus_fixe = category_data["bonus_fixe"] || 0
          montant_m2 + bonus_fixe

        else
          # Type non géré, retourner estimation de base
          case prime.slug
          when /audit/
            400  # Audit énergétique
          when /chaudiere/
            1000 # Chaudière
          when /ventilation/
            2000 # Ventilation
          else
            500  # Estimation générique
          end
        end
      end

      def get_category_data(prime, category)
        return nil unless prime.valeurs_par_categorie.present?

        # Si catégorie multiple, prendre les données de la première catégorie applicable
        if category.include?("-")
          expanded_categories = expand_category_range(category)
          expanded_categories.each do |cat|
            data = prime.valeurs_par_categorie[cat]
            return data if data.present?
          end
          nil
        else
          prime.valeurs_par_categorie[category]
        end
      end

      def estimate_average_surface(prime)
        # Surfaces moyennes selon le type de prime
        case prime.slug
        when /toiture|toit/
          80   # m² toiture moyenne
        when /facade|mur/
          120  # m² façade moyenne
        when /sol|plancher/
          60   # m² sol/plancher moyen
        when /fenetre|porte/
          20   # m² ouvertures moyennes
        else
          100  # Surface générique
        end
      end

      def estimate_average_units(prime)
        # Unités moyennes selon le type de prime
        case prime.slug
        when /escalier/
          15   # marches moyennes
        when /velo/
          2    # emplacements vélo moyens
        when /sanitaire/
          3    # appareils sanitaires moyens
        when /controle/
          1    # contrôle unique
        else
          1    # Unité par défaut
        end
      end

      def estimate_average_work_cost(prime)
        # Coûts moyens de travaux selon le type de prime
        case prime.slug
        when /electricite|gaz/
          8000   # Mise aux normes moyenne
        when /isolation/
          12000  # Isolation moyenne
        when /chauffage/
          6000   # Système chauffage moyen
        when /ventilation/
          5000   # Ventilation moyenne
        else
          10000  # Coût générique
        end
      end
    end
  end
end
