class AddContactedAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :contacted_at, :datetime
  end
end
