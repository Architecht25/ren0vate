class AddIbanAndProtectedClientToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :iban, :string
    add_column :users, :protected_client, :string
  end
end
