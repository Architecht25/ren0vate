class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.string :code
      t.string :description
      t.integer :seuil_seul
      t.integer :seuil_seul_avec_charge
      t.integer :couple_sans_charge
      t.integer :increment_par_personne
      t.boolean :autre_bien_interdit
      t.boolean :location_sociale_autorisee
      t.boolean :eligible_pour_verbouwlening

      t.timestamps
    end
  end
end
