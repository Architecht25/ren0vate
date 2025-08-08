class ChangePropertyIdToOptionalInSimulations < ActiveRecord::Migration[8.0]
  def change
    change_column_null :simulations, :property_id, true
  end
end
