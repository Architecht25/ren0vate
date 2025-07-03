class AddIconNameToPrimes < ActiveRecord::Migration[8.0]
  def change
    add_column :primes, :icon_name, :string
  end
end
