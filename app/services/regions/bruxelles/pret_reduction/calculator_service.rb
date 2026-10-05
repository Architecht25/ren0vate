# Calcul THÉORIQUE de la réduction du solde à rembourser sur un prêt à taux 0% — Bruxelles.
# Mécanisme annoncé pour le printemps 2027, pas encore officialisé : les plafonds et taux
# ci-dessous sont des hypothèses calquées sur le régime wallon (barèmes de revenus et taux
# de réduction identiques). À reprendre dès publication du cadre réglementaire bruxellois.
module Regions
  module Bruxelles
    module PretReduction
      class CalculatorService
        # Plafond d'emprunt hypothétique, identique quel que soit le type de bien.
        PLAFOND_EMPRUNT = 60_000

        def initialize(user, montant_projet:)
          @user = user
          @montant_projet = montant_projet.to_f
        end

        def calculate
          tranche_service = Regions::Wallonie::PretReduction::TrancheService.new(@user)
          montant_retenu = [@montant_projet, PLAFOND_EMPRUNT].min
          taux = tranche_service.taux_reduction

          {
            montant_projet: @montant_projet,
            montant_projet_retenu: montant_retenu,
            plafond_emprunt: PLAFOND_EMPRUNT,
            tranche: tranche_service.tranche,
            taux_reduction: taux,
            reduction_solde: (montant_retenu * taux).round(2),
            # Hypothèse fixe : prêt à taux 0% pour tout ménage éligible (pas de taux réduit).
            taux_interet_label: "0%"
          }
        end
      end
    end
  end
end
