class AddPurchaseDataToProperties < ActiveRecord::Migration[8.0]
  def change
    add_column :properties, :valeur_achat, :decimal, precision: 10, scale: 2
    add_column :properties, :date_achat, :date
  end
end
