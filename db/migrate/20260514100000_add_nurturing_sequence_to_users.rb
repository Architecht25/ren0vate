class AddNurturingSequenceToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :nurturing_n14_sent_at, :datetime
    add_column :users, :nurturing_n30_sent_at, :datetime
    add_column :users, :nurturing_n60_sent_at, :datetime
  end
end
