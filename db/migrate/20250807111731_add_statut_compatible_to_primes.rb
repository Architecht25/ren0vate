class AddStatutCompatibleToPrimes < ActiveRecord::Migration[8.0]
  def change
    add_column :primes, :statut_compatible, :text
  end
end
