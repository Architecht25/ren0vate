class AddStatutVenteToProperties < ActiveRecord::Migration[8.1]
  def change
    add_column :properties, :statut_vente, :string, default: 'actif', null: false
    add_column :properties, :date_mise_en_vente, :date
    add_column :properties, :prix_vente_estime, :decimal, precision: 12, scale: 2
    add_index :properties, :statut_vente
  end
end
