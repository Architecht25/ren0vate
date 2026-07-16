# Taux de réduction du solde à rembourser, par tranche de revenu ajusté du ménage —
# nouveau régime wallon (Rénopack/Rénoprêt, dès le 01/10/2026).
# Ces seuils remplacent les catégories R1-R5 pour les simulations en régime "reduction_pret" ;
# les seeds Prime/Category wallonnes existantes restent inchangées pour le régime "primes_cash".
module Regions
  module Wallonie
    module PretReduction
      class TrancheService
        TRANCHES = [
          { max: 28_900,  taux: 0.50 },
          { max: 41_100,  taux: 0.40 },
          { max: 67_100,  taux: 0.15 },
          { max: 122_800, taux: 0.0 }
        ].freeze

        def initialize(user)
          @user = user
        end

        def adjusted_income
          Regions::Wallonie::HouseholdIncomeCalculator.new(@user).adjusted_income
        end

        def tranche
          TRANCHES.find { |t| adjusted_income <= t[:max] }
        end

        def taux_reduction
          tranche&.fetch(:taux) || 0.0
        end

        def eligible_income?
          tranche.present?
        end
      end
    end
  end
end
