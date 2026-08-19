# Taux de réduction du solde à rembourser, par tranche de revenu ajusté du ménage —
# nouveau régime wallon (Rénopack/Rénoprêt, dès le 01/10/2026).
# Ces seuils remplacent les catégories R1-R5 pour les simulations en régime "reduction_pret" ;
# les seeds Prime/Category wallonnes existantes restent inchangées pour le régime "primes_cash".
#
# `taux_interet` distingue les deux premières colonnes du tableau source (Le Vif, 30/07/2026) :
# les trois tranches jusqu'à 67.100€ donnent accès à un prêt à taux 0% ; la tranche
# 67.100,01-122.800€ n'ouvre plus droit qu'à un taux réduit (non nul, valeur exacte non publiée
# par le texte réglementaire — fixée par la SWCS en comparaison du marché bancaire classique).
module Regions
  module Wallonie
    module PretReduction
      class TrancheService
        TRANCHES = [
          { max: 28_900,  taux: 0.50, taux_interet: :zero },
          { max: 41_100,  taux: 0.40, taux_interet: :zero },
          { max: 67_100,  taux: 0.15, taux_interet: :zero },
          { max: 122_800, taux: 0.0,  taux_interet: :reduit }
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

        # :zero, :reduit, ou nil si le ménage dépasse 122.800€ (aucun prêt bonifié accessible)
        def taux_interet
          tranche&.fetch(:taux_interet)
        end

        def taux_interet_label
          case taux_interet
          when :zero then "0%"
          when :reduit then "Taux réduit"
          else "Non applicable"
          end
        end

        def eligible_income?
          tranche.present?
        end
      end
    end
  end
end
