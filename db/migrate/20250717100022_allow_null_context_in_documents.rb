class AllowNullContextInDocuments < ActiveRecord::Migration[8.0]
  def change
    # Permettre les valeurs nulles pour les colonnes de contexte
    change_column_null :documents, :property_id, true
    change_column_null :documents, :project_id, true
    change_column_null :documents, :request_id, true
    change_column_null :documents, :simulation_id, true
  end
end
