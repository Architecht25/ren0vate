class AddLastProjectAlertAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :last_project_alert_at, :datetime
  end
end
