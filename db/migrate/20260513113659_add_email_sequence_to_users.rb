class AddEmailSequenceToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :onboarding_j1_sent_at, :datetime
    add_column :users, :onboarding_j3_sent_at, :datetime
    add_column :users, :onboarding_j7_sent_at, :datetime
  end
end
