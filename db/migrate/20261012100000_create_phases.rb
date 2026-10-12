# V2 — Lot 1 : découpage du chantier en phases (conception, permis,
# consultation, chantier, réception, après-travaux — cahier des charges §4).
# Même logique que Lot (20261012090000_create_lots.rb) : modèles pré-remplis,
# personnalisables par le propriétaire.
class CreatePhases < ActiveRecord::Migration[8.1]
  def change
    create_table :phases do |t|
      t.references :project, null: false, foreign_key: true
      t.string :key, null: false
      t.string :name, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :phases, [:project_id, :key], unique: true
  end
end
