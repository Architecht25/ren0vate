class AddRegionToRequestsAndMakeSimulationOptional < ActiveRecord::Migration[8.0]
  def change
    # Ajouter la colonne region
    add_column :requests, :region, :string

    # Rendre simulation_id optionnel
    change_column_null :requests, :simulation_id, true

    # Ajouter les champs title et description pour les nouvelles demandes
    add_column :requests, :title, :string
    add_column :requests, :description, :text
  end
end
