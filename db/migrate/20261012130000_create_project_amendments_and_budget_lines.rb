# V2 — Lot 2 : Amendment (avenant, cahier des charges §4 : "motif, delta de
# montant, validation propriétaire tracée") et BudgetLine (prévisionnel par
# lot, §4). Le rapprochement prévisionnel/devisé/facturé/payé complet
# (Invoice/Payment restent à construire) est hors scope de ce lot — voir
# docs/PLAN_V2.md.
class CreateProjectAmendmentsAndBudgetLines < ActiveRecord::Migration[8.1]
  def change
    create_table :project_amendments do |t|
      t.references :project, null: false, foreign_key: true
      t.references :project_quote, null: true, foreign_key: true
      t.references :requested_by, null: false, foreign_key: { to_table: :users }
      t.references :validated_by, null: true, foreign_key: { to_table: :users }

      t.text :motif, null: false
      t.decimal :delta_montant, precision: 10, scale: 2, null: false
      t.string :status, null: false, default: "propose"
      t.datetime :validated_at

      t.timestamps
    end

    create_table :budget_lines do |t|
      t.references :project, null: false, foreign_key: true
      t.references :lot, null: true, foreign_key: true

      t.string :label, null: false
      t.decimal :montant_prevu, precision: 10, scale: 2, null: false

      t.timestamps
    end
  end
end
