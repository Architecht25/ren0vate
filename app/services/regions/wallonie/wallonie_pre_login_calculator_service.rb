# Calculateur de primes pré-login pour la Wallonie
# Version simplifiée pour utilisateurs non connectés

module Regions
  module Wallonie
    class WalloniePreLoginCalculatorService < Regions::BaseService
      def calculate_primes(category_result)
        log_calculation("Début calcul primes pré-login Wallonie", category_result)

        category = category_result[:category]
        primes = Prime.where(region: 'wallonie').order(:ordre_affichage)

        calculate_estimated_primes(primes, category)
      end

      private

      def calculate_estimated_primes(primes, category)
        calculated_primes = []

        primes.each do |prime|
          # Vérifier l'éligibilité à cette prime pour cette catégorie
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
            disclaimer: "Estimation basée sur des valeurs moyennes. Montant exact après connexion."
          }
        end

        calculated_primes
      end

      def prime_eligible_for_category?(prime, category)
        return false unless prime.eligible_categories.present?

        # Gérer les catégories multiples comme "R1-R4"
        if category.include?("-")
          expanded_categories = expand_category_range(category)
          expanded_categories.any? { |cat| prime.eligible_categories.include?(cat) }
        else
          prime.eligible_categories.include?(category)
        end
      end

      def expand_category_range(category_range)
        # "R1-R4" devient ["R1", "R2", "R3", "R4"]
        if category_range == "R1-R4"
          %w[R1 R2 R3 R4]
        else
          [category_range]
        end
      end

      def estimate_prime_amount(prime, category)
        # Utiliser des valeurs moyennes pour l'estimation
        category_data = get_category_data(prime, category)
        return 0 unless category_data

        case category_data["type"]
        when "montant_fixe"
          category_data["montant"] || 0
        when "montant_m2"
          # Estimation avec surface moyenne de 100m²
          (category_data["montant_m2"] || 0) * 100
        when "pourcentage"
          # Estimation avec montant moyen de 10 000€ de travaux
          ((category_data["pourcentage"] || 0) * 10000) / 100
        when "montant_variable"
          # Prendre la valeur moyenne des montants possibles
          montants = category_data["montants"] || {}
          return 0 if montants.empty?
          montants.values.sum / montants.size
        else
          # Type non géré, retourner une estimation de base
          1000
        end
      end

      def get_category_data(prime, category)
        return nil unless prime.valeurs_par_categorie.present?

        # Si catégorie multiple, prendre la moyenne des catégories applicables
        if category.include?("-")
          expanded_categories = expand_category_range(category)
          valid_data = expanded_categories.map { |cat| prime.valeurs_par_categorie[cat] }.compact
          return nil if valid_data.empty?

          # Retourner les données de la première catégorie trouvée pour simplifier
          valid_data.first
        else
          prime.valeurs_par_categorie[category]
        end
      end
    end
  end
end
