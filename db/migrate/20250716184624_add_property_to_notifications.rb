class AddPropertyToNotifications < ActiveRecord::Migration[8.0]
  def change
    add_reference :notifications, :property, null: true, foreign_key: true
  end
end
