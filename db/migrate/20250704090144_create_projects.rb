class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.references :property, null: false, foreign_key: true
      t.string :nom
      t.text :description
      t.string :statut
      t.string :intervenant_entrepreneur
      t.string :intervenant_architecte
      t.date :date_début
      t.date :date_fin

      t.timestamps
    end
  end
end
