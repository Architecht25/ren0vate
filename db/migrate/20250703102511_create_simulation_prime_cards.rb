class CreateSimulationPrimeCards < ActiveRecord::Migration[8.0]
  def change
    create_table :simulation_prime_cards do |t|
      t.references :simulation, null: false, foreign_key: true
      t.references :prime, null: false, foreign_key: true
      t.decimal :montant_calcule
      t.string :categorie
      t.boolean :inactif
      t.text :explication_calculee
      t.jsonb :input_donnees

      t.timestamps
    end
  end
end
