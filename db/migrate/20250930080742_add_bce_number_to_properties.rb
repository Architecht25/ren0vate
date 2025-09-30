class AddBceNumberToProperties < ActiveRecord::Migration[8.0]
  def change
    add_column :properties, :bce_number, :string
  end
end
