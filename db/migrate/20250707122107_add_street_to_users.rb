class AddStreetToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :street, :string
  end
end
