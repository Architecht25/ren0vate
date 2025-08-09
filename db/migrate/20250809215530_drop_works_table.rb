class DropWorksTable < ActiveRecord::Migration[8.0]
  def change
    drop_table :works
  end
end
