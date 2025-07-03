class CreateSimulationPrimeCards < ActiveRecord::Migration[8.0]
  def change
    create_table :simulation_prime_cards do |t|
      t.references :simulation, null: false, foreign_key: true
      t.references :prime, null: false, foreign_key: true
      t.decimal :montant_simule

      t.timestamps
    end
  end
end
