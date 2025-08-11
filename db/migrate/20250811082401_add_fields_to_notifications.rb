class AddFieldsToNotifications < ActiveRecord::Migration[8.0]
  def change
    add_column :notifications, :title, :string
    add_column :notifications, :category, :string
    add_column :notifications, :action_url, :string
    add_column :notifications, :read_at, :datetime
    add_column :notifications, :priority, :integer
    add_column :notifications, :expires_at, :datetime
  end
end
