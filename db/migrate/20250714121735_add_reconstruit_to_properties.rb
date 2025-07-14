class AddReconstruitToProperties < ActiveRecord::Migration[8.0]
  def change
    add_column :properties, :reconstruit, :string
  end
end
