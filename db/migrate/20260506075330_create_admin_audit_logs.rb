class CreateAdminAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_audit_logs do |t|
      t.integer :admin_id, null: false
      t.integer :target_user_id
      t.string :action, null: false
      t.string :ip_address
      t.string :user_agent
      t.text :metadata

      t.timestamps
    end

    add_index :admin_audit_logs, :admin_id
    add_index :admin_audit_logs, :action
    add_index :admin_audit_logs, :created_at
  end
end
