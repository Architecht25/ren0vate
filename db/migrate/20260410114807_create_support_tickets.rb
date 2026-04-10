class CreateSupportTickets < ActiveRecord::Migration[8.0]
  def change
    create_table :support_tickets do |t|
      t.references :user, null: false, foreign_key: true
      t.string :subject, null: false
      t.string :status, null: false, default: 'open'
      t.string :priority, null: false, default: 'normal'
      t.datetime :responded_at

      t.timestamps
    end

    add_index :support_tickets, :status
    add_index :support_tickets, :created_at
  end
end
