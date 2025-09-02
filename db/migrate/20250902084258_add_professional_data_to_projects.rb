class AddProfessionalDataToProjects < ActiveRecord::Migration[8.0]
  def change
    # Données détaillées de l'architecte
    add_column :projects, :architecte_nom, :string
    add_column :projects, :architecte_prenom, :string
    add_column :projects, :architecte_entreprise, :string
    add_column :projects, :architecte_numero_ordre, :string
    add_column :projects, :architecte_telephone, :string
    add_column :projects, :architecte_email, :string
    add_column :projects, :architecte_adresse, :text
    add_column :projects, :architecte_specialites, :text # Stockage JSON des spécialités

    # Données de l'entrepreneur principal
    add_column :projects, :entrepreneur_principal_nom, :string
    add_column :projects, :entrepreneur_principal_entreprise, :string
    add_column :projects, :entrepreneur_principal_numero_tva, :string
    add_column :projects, :entrepreneur_principal_telephone, :string
    add_column :projects, :entrepreneur_principal_email, :string
    add_column :projects, :entrepreneur_principal_adresse, :text
    add_column :projects, :entrepreneur_principal_assurance, :string
    add_column :projects, :entrepreneur_principal_certifications, :text # Stockage JSON

    # Corps de métiers supplémentaires (stockage JSON pour flexibilité)
    add_column :projects, :corps_metiers, :text # Format JSON pour multiple corps de métiers

    # Informations générales du chantier
    add_column :projects, :maitre_ouvrage_nom, :string
    add_column :projects, :maitre_ouvrage_contact, :string
    add_column :projects, :coordinateur_securite_nom, :string
    add_column :projects, :coordinateur_securite_contact, :string

    # Assurances et garanties
    add_column :projects, :assurance_decennale_architecte, :string
    add_column :projects, :assurance_decennale_entrepreneur, :string
    add_column :projects, :garanties_travaux, :text
  end
end
