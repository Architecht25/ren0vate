class AddBruxellesStatusToUsers < ActiveRecord::Migration[8.0]
  def change
    # Statuts spéciaux Bruxelles
    add_column :users, :bim, :boolean, default: false
    add_column :users, :ris, :boolean, default: false
    add_column :users, :client_protege_bruxelles, :boolean, default: false
    add_column :users, :independant, :boolean, default: false
    add_column :users, :tva_deductible, :boolean, default: false
    add_column :users, :statut_professionnel, :string
    add_column :users, :vente_prevue_5_ans, :boolean, default: false
    add_column :users, :consentement_controles, :boolean, default: false
    # iban existe déjà
    add_column :users, :compte_bancaire_belge, :boolean, default: false
    add_column :users, :type_demandeur, :string
  end
end
