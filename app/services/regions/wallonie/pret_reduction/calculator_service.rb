# Calcul de la réduction du solde à rembourser — nouveau régime wallon (dès le 01/10/2026).
# Contrairement à l'ancien régime (primes par poste de travaux via le modèle Prime),
# le calcul se fait sur le coût global du projet, plafonné selon le type de bien, avec un
# taux de réduction unique déterminé par la tranche de revenu du ménage.
module Regions
  module Wallonie
    module PretReduction
      class CalculatorService
        # Source : wallonie.be (décision gouvernementale du 16/07/2026) — confirmé par
        # Le Vif (30/07/2026) : 75.000€ pour une maison unifamiliale, 60.000€ par logement
        # pour un appartement. Pour les parties communes d'une copropriété (dossier introduit
        # par le syndic, `profil_demandeur == "syndic_copropriété"`), le plafond est forfaitaire
        # selon le nombre de lots : 600.000€ (< 20 lots) ou 750.000€ (≥ 20 lots).
        PLAFOND_MAISON = 75_000
        PLAFOND_APPARTEMENT = 60_000
        PLAFOND_PARTIES_COMMUNES_MOINS_20_LOTS = 600_000
        PLAFOND_PARTIES_COMMUNES_20_LOTS_OU_PLUS = 750_000
        SEUIL_LOTS_PARTIES_COMMUNES = 20

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
          return plafond_parties_communes if @property&.profil_demandeur == "syndic_copropriété"

          case @property&.type_bien_wallonie
          when "appartement_studio"
            PLAFOND_APPARTEMENT
          else
            PLAFOND_MAISON
          end
        end

        # Nombre de lots non renseigné : on retient par défaut le plafond le plus bas
        # (600.000€) plutôt que de surestimer le montant finançable.
        def plafond_parties_communes
          lots = @property&.nombre_lots_copropriete
          return PLAFOND_PARTIES_COMMUNES_MOINS_20_LOTS if lots.blank?

          lots >= SEUIL_LOTS_PARTIES_COMMUNES ? PLAFOND_PARTIES_COMMUNES_20_LOTS_OU_PLUS : PLAFOND_PARTIES_COMMUNES_MOINS_20_LOTS
        end
      end
    end
  end
end
