# V2 — Lot 3 : moteur de primes (cahier des charges §9). Remplace les
# services Regions::* V1 (règles codées en dur dans des classes Ruby, une
# réforme = un déploiement) par des règles VERSIONNÉES ET DATÉES EN BASE
# (SubsidyRule) : une réforme = une nouvelle ligne, sans toucher au code.
#
# conditions (jsonb) : liste de { "field", "operator", "value" }, évaluées
# en ET par Subsidies::RuleEngine contre un input_data structuré
# (property.*, household.*, travaux.*). amount_formula (jsonb) : { "type":
# "flat"|"percentage"|"per_unit", ... } — voir Subsidies::RuleEngine pour
# le détail de chaque type.
class CreateSubsidyEngine < ActiveRecord::Migration[8.1]
  def change
    create_table :subsidy_rules do |t|
      t.string :region, null: false
      t.string :key, null: false
      t.string :label, null: false
      t.date :valid_from, null: false
      t.date :valid_to
      t.jsonb :conditions, null: false, default: []
      t.jsonb :amount_formula, null: false, default: {}

      t.timestamps
    end
    add_index :subsidy_rules, [:region, :key, :valid_from]

    create_table :subsidy_document_requirements do |t|
      t.references :subsidy_rule, null: false, foreign_key: true
      t.string :document_type, null: false
      t.boolean :mandatory, null: false, default: true

      t.timestamps
    end

    create_table :subsidy_cases do |t|
      t.references :project, null: true, foreign_key: true
      t.references :user, null: true, foreign_key: true

      t.string :region, null: false
      t.string :mode, null: false, default: "simulation"
      t.jsonb :input_data, null: false, default: {}

      t.timestamps
    end
    add_index :subsidy_cases, [:project_id, :region]

    create_table :subsidy_case_results do |t|
      t.references :subsidy_case, null: false, foreign_key: true
      t.references :subsidy_rule, null: false, foreign_key: true

      t.boolean :eligible, null: false
      t.decimal :amount_estimated, precision: 10, scale: 2
      t.jsonb :reasons, null: false, default: []

      t.datetime :created_at, null: false
      # Pas d'updated_at : un résultat de calcul est un fait historique (quelles
      # règles, quelle date) — un recalcul crée une nouvelle ligne, n'écrase pas.
    end
  end
end
