class AddPlafondToPrimes < ActiveRecord::Migration[6.0]
  def change
    add_column :primes, :plafond, :decimal, precision: 10, scale: 2
  end
end
