class CreateChantierAnalyses < ActiveRecord::Migration[8.0]
  def change
    create_table :chantier_analyses do |t|
      t.references :project, null: false, foreign_key: true
      t.integer :avancement
      t.string :phase
      t.text :observations
      t.text :alertes
      t.text :prochaines_etapes
      t.integer :photos_count
      t.datetime :analysed_at

      t.timestamps
    end
  end
end
