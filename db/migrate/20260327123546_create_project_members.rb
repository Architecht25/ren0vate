class CreateProjectMembers < ActiveRecord::Migration[8.0]
  def change
    create_table :project_members do |t|
      t.references :project,        null: false, foreign_key: true
      t.references :user,           null: false, foreign_key: true
      t.string     :role,           null: false  # owner | entrepreneur | architect
      t.string     :status,         null: false, default: 'pending'  # pending | active
      t.string     :invite_token
      t.string     :invited_email   # email utilisé pour l'invitation (avant création compte)
      t.datetime   :invite_sent_at
      t.datetime   :accepted_at
      t.datetime   :invite_expires_at
      t.timestamps
    end

    add_index :project_members, [:project_id, :user_id], unique: true
    add_index :project_members, :invite_token, unique: true, where: "invite_token IS NOT NULL"
  end
end
