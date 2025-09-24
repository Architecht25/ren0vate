class AddEmailTrackingFieldsToRequestProgresses < ActiveRecord::Migration[8.0]
  def change
    add_column :request_progresses, :extracted_data, :text, comment: "Données JSON extraites des documents reçus par email"
    add_column :request_progresses, :email_processed_at, :datetime, comment: "Date de traitement du dernier email reçu"
    add_column :request_progresses, :document_extraction_status, :string, default: 'pending', comment: "Statut de l'extraction: pending, processing, completed, failed"

    add_index :request_progresses, :document_extraction_status
    add_index :request_progresses, :email_processed_at
  end
end
