class AddTypeIntervenantToFactures < ActiveRecord::Migration[8.0]
  def change
    add_column :factures, :type_intervenant, :string, default: 'entrepreneur',
               comment: 'Type: architecte, entrepreneur, autre'
    add_column :factures, :adresse_entreprise, :text,
               comment: 'Adresse extraite par OCR'
    add_column :factures, :telephone_entreprise, :string,
               comment: 'Téléphone extrait par OCR'
    add_column :factures, :email_entreprise, :string,
               comment: 'Email extrait par OCR'
    add_index :factures, :type_intervenant
  end
end
