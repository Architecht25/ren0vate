class CreateWorks < ActiveRecord::Migration[8.0]
  def change
    create_table :works do |t|
      t.references :project, null: false, foreign_key: true
      t.integer :surface
      t.float :montant_estimé
      t.string :type
      t.references :prime, null: false, foreign_key: true

      t.timestamps
    end
  end
end
