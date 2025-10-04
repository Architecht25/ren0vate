class CreateComplementRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :complement_requests do |t|
      t.references :request_progress, null: false, foreign_key: true

      # Type et contenu de la demande
      t.string :complement_type, null: false
      t.text :admin_message, null: false
      t.json :required_documents, default: []
      t.string :priority, default: 'normal'

      # Dates et délais
      t.date :deadline, null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :expired_at
      t.datetime :approved_at
      t.datetime :rejected_at

      # Réponse du client
      t.text :client_response
      t.text :rejection_reason

      # Statut
      t.string :status, null: false, default: 'pending'

      t.timestamps
    end

    add_index :complement_requests, :status
    add_index :complement_requests, :deadline
    add_index :complement_requests, [:request_progress_id, :status]
    add_index :complement_requests, :complement_type
  end
end
