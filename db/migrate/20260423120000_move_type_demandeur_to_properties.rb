class MoveTypeDemandeurToProperties < ActiveRecord::Migration[8.0]
  def change
    # Ajout du type de demandeur sur le bien (niveau propriété)
    add_column :properties, :type_demandeur, :string

    # Suppression des colonnes bruit sur les utilisateurs
    remove_column :users, :statut_professionnel, :string
    remove_column :users, :independant, :boolean
    remove_column :users, :bim, :boolean
    remove_column :users, :ris, :boolean
    remove_column :users, :client_protege_bruxelles, :boolean
    remove_column :users, :tva_deductible, :boolean
    remove_column :users, :compte_bancaire_belge, :boolean
    remove_column :users, :vente_prevue_5_ans, :boolean
    remove_column :users, :consentement_controles, :boolean
    remove_column :users, :type_demandeur, :string
  end
end
