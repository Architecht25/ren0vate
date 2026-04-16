class CreateReserves < ActiveRecord::Migration[8.0]
  def change
    create_table :reserves do |t|
      t.references :project, null: false, foreign_key: true
      t.text :description
      t.string :responsable
      t.date :date_constat
      t.date :date_limite
      t.string :statut, default: 'ouverte', null: false
      t.text :notes

      t.timestamps
    end

    add_index :reserves, [:project_id, :statut]
  end
end
