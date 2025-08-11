class AddRelationsToNotifications < ActiveRecord::Migration[8.0]
  def change
    add_reference :notifications, :project, null: true, foreign_key: true
    add_reference :notifications, :simulation, null: true, foreign_key: true
  end
end
