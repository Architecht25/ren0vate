class RemoveUnusedColumnsFromProjectsPropertiesAndPrimes < ActiveRecord::Migration[8.0]
  def change
    # Suppression des colonnes inutilisées de la table projects
    remove_column :projects, :intervenant_entrepreneur, :string
    remove_column :projects, :intervenant_architecte, :string
    remove_column :projects, :assurance_decennale_architecte, :string
    remove_column :projects, :assurance_decennale_entrepreneur, :string
    remove_column :projects, :entrepreneur_principal_assurance, :string

    # Suppression de la colonne inutilisée de la table properties
    remove_column :properties, :bce_number, :string

    # Suppression de la colonne inutilisée de la table primes
    remove_column :primes, :categorie_visible, :string
  end
end
