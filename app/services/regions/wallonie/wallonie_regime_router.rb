# Détermine quel régime wallon s'applique à une simulation : "primes_cash" (historique)
# ou "reduction_pret" (Rénopack/Rénoprêt). La réforme n'entre légalement en vigueur que le
# 01/10/2026, mais Ren0vate bascule ses NOUVELLES simulations dès maintenant : le régime
# actuel disparaît dans ~2,5 mois, plus personne ne construit un dossier sur cette base.
# Les simulations déjà créées gardent leur régime d'origine (avant_create uniquement).
# Seul endroit où la date de bascule est écrite en dur.
module Regions
  module Wallonie
    class WallonieRegimeRouter
      REFORME_DATE = Date.new(2026, 7, 17)

      def self.regime_for(date: Date.current)
        date >= REFORME_DATE ? "reduction_pret" : "primes_cash"
      end
    end
  end
end
