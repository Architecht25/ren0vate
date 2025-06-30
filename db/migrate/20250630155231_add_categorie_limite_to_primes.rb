class AddCategorieLimiteToPrimes < ActiveRecord::Migration[8.0]
  def change
    add_column :primes, :categorie_limite, :string
  end
end
