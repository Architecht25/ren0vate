# V2 — Lot 0 : introduit le découpage d'un chantier en lots (toiture,
# menuiseries, isolation, techniques, finitions...), nécessaire au périmètre
# d'intervention par intervenant (cahier des charges V2 §3-4).
class CreateLots < ActiveRecord::Migration[8.1]
  def change
    create_table :lots do |t|
      t.references :project, null: false, foreign_key: true
      t.string :key, null: false # ex: "toiture", "menuiseries" — stable, utilisé pour les modèles pré-remplis
      t.string :name, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :lots, [:project_id, :key], unique: true
  end
end
