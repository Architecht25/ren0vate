class AllowNullPropertyIdInRequests < ActiveRecord::Migration[8.0]
  def change
    change_column_null :requests, :property_id, true
  end
end
