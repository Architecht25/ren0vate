# V2 — Lot 2 : prévisionnel par lot (cahier des charges §4-5.C). Le
# rapprochement complet prévisionnel/devisé/facturé/payé attend les
# modèles Invoice/Payment (hors scope de ce lot) — seul prévisionnel vs
# devisé (somme des ProjectQuote acceptés du lot) est calculé pour l'instant,
# voir Lot#budget_summary.
class BudgetLine < ApplicationRecord
  belongs_to :project
  belongs_to :lot, optional: true

  validates :label, presence: true
  validates :montant_prevu, numericality: { greater_than_or_equal_to: 0 }
end
