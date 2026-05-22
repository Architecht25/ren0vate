class AddSourceToPvReceptions < ActiveRecord::Migration[8.1]
  def change
    add_column :pv_receptions, :source, :string
  end
end
