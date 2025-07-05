class AddGroupeToPrimes < ActiveRecord::Migration[6.0]
  def change
    add_column :primes, :groupe, :string
  end
end
