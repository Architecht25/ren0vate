class AddCategorieEmetteurToDevisDonnees < ActiveRecord::Migration[8.0]
  def change
    add_column :devis_donnees, :categorie_emetteur, :string
    add_index  :devis_donnees, :categorie_emetteur
  end
end
