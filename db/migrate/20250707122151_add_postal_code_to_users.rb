class AddPostalCodeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :postal_code, :string
  end
end
