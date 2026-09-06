class CreateFinancingSources < ActiveRecord::Migration[8.1]
  def change
    create_table :financing_sources do |t|
      t.references :project, null: false, foreign_key: true
      t.references :simulation, foreign_key: true, null: true
      t.references :pret_wallonie_dossier, foreign_key: true, null: true
      t.string  :label, null: false
      t.integer :source_type, null: false
      t.integer :status, null: false, default: 0
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.decimal :rate, precision: 5, scale: 3
      t.integer :duration_months
      t.text    :notes

      t.timestamps
    end

    add_index :financing_sources, %i[project_id source_type]
  end
end
