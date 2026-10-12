# V2 — Lot 2 : journal de tout appel IA (cahier des charges §8 : "Une seule
# couche Ai::Client... journalisation dans AiRun"). Fonction, modèle, entrée
# référencée (polymorphe), sortie structurée, coût estimé, validation humaine.
class CreateAiRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_runs do |t|
      t.references :project, null: false, foreign_key: true
      t.references :actor, null: true, foreign_key: { to_table: :users } # nil = job système sans utilisateur à l'origine
      t.references :subject, polymorphic: true, null: true # entrée référencée, ex: ProjectDocumentVersion
      t.references :validated_by, null: true, foreign_key: { to_table: :users }

      t.string :function, null: false
      t.string :model, null: false
      t.string :status, null: false, default: "pending"
      t.jsonb :output, null: false, default: {}
      t.float :confidence
      t.integer :estimated_cost_cents
      t.datetime :validated_at

      t.timestamps
    end

    add_index :ai_runs, [:project_id, :created_at]
    add_index :ai_runs, :function
  end
end
