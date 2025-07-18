class AddCalculDetailsToSimulationPrimeCards < ActiveRecord::Migration[8.0]
  def change
    add_column :simulation_prime_cards, :calcul_details, :text
  end
end
