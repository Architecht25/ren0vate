# Calcul de la réduction du solde à rembourser — nouveau régime wallon (dès le 01/10/2026).
# Contrairement à l'ancien régime (primes par poste de travaux via le modèle Prime),
# le calcul se fait sur le coût global du projet, plafonné selon le type de bien, avec un
# taux de réduction unique déterminé par la tranche de revenu du ménage.
module Regions
  module Wallonie
    module PretReduction
      class CalculatorService
        # Source : Le Vif (30/07/2026, tableau "Quels prêts et quelles aides pour quels
        # ménages ?") — 75.000€ pour une maison unifamiliale, 60.000€ pour un appartement/studio.
        # NB : l'article mentionne aussi une majoration de 60.000€ par logement pour les
        # parties communes d'un immeuble à plusieurs unités — non implémentée ici, car
        # Property ne porte pas encore de champ "nombre de logements de l'immeuble".
        # À ajouter si ce type de dossier (type_bien_wallonie == "immeuble_plusieurs_unites")
        # se présente en pratique.
        PLAFOND_MAISON = 75_000
        PLAFOND_APPARTEMENT = 60_000

        # Majoration de 5 points de pourcentage du taux de réduction en cas d'utilisation
        # d'écomatériaux (source : Le Vif, 30/07/2026, note (2) du tableau des tranches).
        MAJORATION_ECOMATERIAUX = 0.05

        def initialize(user, montant_projet:, property: nil, ecomateriaux: false)
          @user = user
          @montant_projet = montant_projet.to_f
          @property = property
          @ecomateriaux = ActiveModel::Type::Boolean.new.cast(ecomateriaux)
        end

        def calculate
          tranche_service = Regions::Wallonie::PretReduction::TrancheService.new(@user)
          plafond = plafond_emprunt
          montant_projet_retenu = [@montant_projet, plafond].min
          taux_base = tranche_service.taux_reduction
          taux = @ecomateriaux ? (taux_base + MAJORATION_ECOMATERIAUX) : taux_base

          {
            montant_projet: @montant_projet,
            montant_projet_retenu: montant_projet_retenu,
            plafond_emprunt: plafond,
            tranche: tranche_service.tranche,
            ecomateriaux: @ecomateriaux,
            taux_reduction_base: taux_base,
            taux_reduction: taux,
            reduction_solde: (montant_projet_retenu * taux).round(2),
            taux_interet: tranche_service.taux_interet,
            taux_interet_label: tranche_service.taux_interet_label
          }
        end

        private

        def plafond_emprunt
          case @property&.type_bien_wallonie
          when "appartement_studio"
            PLAFOND_APPARTEMENT
          else
            PLAFOND_MAISON
          end
        end
      end
    end
  end
end
