class AddAnalyseContenuToDevisDonnees < ActiveRecord::Migration[8.1]
  def change
    add_column :devis_donnees, :postes_json, :jsonb, default: [], null: false
    add_column :devis_donnees, :analyse_contenu_statut, :string, default: 'non_lancee', null: false
    add_column :devis_donnees, :analyse_contenu_confiance, :decimal, precision: 5, scale: 2
    add_column :devis_donnees, :analyse_contenu_erreur, :string
    add_column :devis_donnees, :analyse_contenu_effectuee_at, :datetime

    add_index :devis_donnees, :analyse_contenu_statut
  end
end
