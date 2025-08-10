class AddDetailedFieldsToEntrepriseAides < ActiveRecord::Migration[8.0]
  def change
    add_column :entreprise_aides, :modalites_paiement, :jsonb
    add_column :entreprise_aides, :delais_procedures, :jsonb
  end
end
