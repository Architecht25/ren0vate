class AddCategoryToSupportTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :support_tickets, :category, :string, default: 'general', null: false
  end
end
