class AddCategorieVisibleToPrimes < ActiveRecord::Migration[8.0]
  def change
    add_column :primes, :categorie_visible, :string
  end
end
