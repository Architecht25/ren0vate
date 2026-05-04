class AddReminderSentAtToProjectMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :project_members, :reminder_sent_at, :datetime
  end
end
