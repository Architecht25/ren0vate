class AddCategoryIdToPrimes < ActiveRecord::Migration[6.0]
  def change
    add_column :primes, :category_id, :bigint
    add_foreign_key :primes, :categories
  end
end
