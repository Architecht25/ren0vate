class AddRegionToCategories < ActiveRecord::Migration[8.0]
  def change
    add_column :categories, :region, :string
    add_index :categories, :region
    add_index :categories, [:region, :code], unique: true
  end
end
