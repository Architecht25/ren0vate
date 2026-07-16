class AddRegimeToSimulations < ActiveRecord::Migration[8.1]
  def change
    add_column :simulations, :regime, :string, default: "primes_cash"
    add_index :simulations, :regime
  end
end
