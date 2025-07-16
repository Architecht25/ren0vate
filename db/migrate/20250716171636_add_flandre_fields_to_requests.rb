class AddFlandreFieldsToRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :requests, :domicile, :boolean
    add_column :requests, :type_demandeur, :string
    add_column :requests, :registre_national, :string
    add_column :requests, :nom, :string
    add_column :requests, :prenom, :string
    add_column :requests, :telephone, :string
    add_column :requests, :email, :string
    add_column :requests, :ean, :string
    add_column :requests, :parcelle, :string
    add_column :requests, :adresse, :string
    add_column :requests, :code_postal, :string
    add_column :requests, :commune, :string
    add_column :requests, :type_bien, :string
    add_column :requests, :usage, :string
    add_column :requests, :chauffage_post_renovation, :string
    add_column :requests, :travaux_toiture, :boolean
    add_column :requests, :travaux_murs, :boolean
    add_column :requests, :travaux_sol, :boolean
    add_column :requests, :travaux_vitrage, :boolean
    add_column :requests, :travaux_chauffage, :boolean
    add_column :requests, :travaux_complementaires, :boolean
    add_column :requests, :travaux_ventilation, :boolean
    add_column :requests, :travaux_solaire, :boolean
    add_column :requests, :revenus_annuels, :integer
    add_column :requests, :personnes_charge, :integer
    add_column :requests, :annee_aer, :string
    add_column :requests, :compte_bancaire, :string
    add_column :requests, :email_contact, :string
    add_column :requests, :telephone_contact, :string
    add_column :requests, :confirmation_veracite, :boolean
    add_column :requests, :acceptation_conditions, :boolean
  end
end
