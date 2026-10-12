# V2 — Lot 3 : résultat de calcul pour une règle donnée, à un instant donné
# (cahier des charges §9 : "Tout résultat affiche ses hypothèses et sa date
# de règles"). Append-only — un recalcul crée une nouvelle ligne.
class SubsidyCaseResult < ApplicationRecord
  belongs_to :subsidy_case
  belongs_to :subsidy_rule

  before_update { raise ActiveRecord::ReadOnlyRecord, "SubsidyCaseResult est append-only : aucune modification après création" }
  before_destroy { raise ActiveRecord::ReadOnlyRecord, "SubsidyCaseResult est append-only : aucune suppression" }
end
