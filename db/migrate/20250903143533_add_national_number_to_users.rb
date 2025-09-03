class AddNationalNumberToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :national_number, :string
  end
end
