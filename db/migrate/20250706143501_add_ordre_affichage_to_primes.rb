class AddOrdreAffichageToPrimes < ActiveRecord::Migration[8.0]
  def change
    add_column :primes, :ordre_affichage, :integer
  end
end
