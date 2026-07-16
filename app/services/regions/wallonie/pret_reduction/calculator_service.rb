# Calcul de la réduction du solde à rembourser — nouveau régime wallon (dès le 01/10/2026).
# Contrairement à l'ancien régime (primes par poste de travaux via le modèle Prime),
# le calcul se fait sur le coût global du projet, plafonné à 75 000€, avec un taux de
# réduction unique déterminé par la tranche de revenu du ménage.
module Regions
  module Wallonie
    module PretReduction
      class CalculatorService
        PLAFOND_EMPRUNT = 75_000

        def initialize(user, montant_projet:)
          @user = user
          @montant_projet = montant_projet.to_f
        end

        def calculate
          tranche_service = Regions::Wallonie::PretReduction::TrancheService.new(@user)
          montant_projet_retenu = [@montant_projet, PLAFOND_EMPRUNT].min
          taux = tranche_service.taux_reduction

          {
            montant_projet: @montant_projet,
            montant_projet_retenu: montant_projet_retenu,
            plafond_emprunt: PLAFOND_EMPRUNT,
            tranche: tranche_service.tranche,
            taux_reduction: taux,
            reduction_solde: (montant_projet_retenu * taux).round(2)
          }
        end
      end
    end
  end
end
