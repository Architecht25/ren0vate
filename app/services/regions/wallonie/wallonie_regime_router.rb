# Détermine quel régime wallon s'applique à une simulation : "primes_cash" (historique,
# jusqu'au 30/09/2026) ou "reduction_pret" (Rénopack/Rénoprêt, dès le 01/10/2026).
# Seul endroit où la date de bascule est écrite en dur — à ajuster ici si le Conseil
# d'État ou le conclave budgétaire de rentrée imposent un report.
module Regions
  module Wallonie
    class WallonieRegimeRouter
      REFORME_DATE = Date.new(2026, 10, 1)

      def self.regime_for(date: Date.current)
        date >= REFORME_DATE ? "reduction_pret" : "primes_cash"
      end
    end
  end
end
