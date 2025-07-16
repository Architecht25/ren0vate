class AddRegionSpecificFieldsToRequests < ActiveRecord::Migration[8.0]
  def change
    # Champs spécifiques à Bruxelles
    add_column :requests, :revenus_menage, :integer
    add_column :requests, :nombre_personnes, :integer
    add_column :requests, :type_travaux, :string
    add_column :requests, :surface_travaux, :decimal, precision: 10, scale: 2
    add_column :requests, :cout_estime, :decimal, precision: 10, scale: 2
    
    # Champs spécifiques à la Wallonie
    add_column :requests, :revenus_reference, :integer
    add_column :requests, :composition_menage, :string
    add_column :requests, :categories_travaux, :string
    add_column :requests, :logement_principal, :boolean
    add_column :requests, :montant_travaux, :decimal, precision: 10, scale: 2
    
    # Champs spécifiques à la Flandre
    add_column :requests, :inkomen_gezin, :integer
    add_column :requests, :gezinssamenstelling, :string
    add_column :requests, :type_renovatie, :string
    add_column :requests, :eigenaar_bewoner, :boolean
    add_column :requests, :kostprijs_werken, :decimal, precision: 10, scale: 2
  end
end
