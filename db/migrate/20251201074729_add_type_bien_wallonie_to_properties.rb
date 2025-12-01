class AddTypeBienWallonieToProperties < ActiveRecord::Migration[8.0]
  def change
    add_column :properties, :type_bien_wallonie, :string
  end
end
