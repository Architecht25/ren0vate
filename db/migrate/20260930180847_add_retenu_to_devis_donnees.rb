class AddRetenuToDevisDonnees < ActiveRecord::Migration[8.1]
  def change
    add_column :devis_donnees, :retenu, :boolean, default: false, null: false
    add_index :devis_donnees, [:project_id, :categorie_emetteur, :retenu]
  end
end
