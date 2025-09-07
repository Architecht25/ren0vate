class AddDateCreationToProperties < ActiveRecord::Migration[8.0]
  def change
    add_column :properties, :date_creation, :date
  end
end
