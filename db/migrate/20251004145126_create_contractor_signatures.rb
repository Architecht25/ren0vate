class CreateContractorSignatures < ActiveRecord::Migration[8.0]
  def change
    create_table :contractor_signatures do |t|
      t.references :request, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true # L'entrepreneur s'il a un compte

      # Informations entrepreneur
      t.string :contractor_name, null: false
      t.string :contractor_email, null: false
      t.string :contractor_phone, null: false
      t.string :contractor_company
      t.string :contractor_registration_number

      # Description du travail
      t.text :work_description, null: false
      t.string :work_type, null: false
      t.decimal :estimated_amount, precision: 10, scale: 2

      # Statut et workflow
      t.string :status, null: false, default: 'pending'
      t.string :signature_token, null: false
      t.date :expiry_date

      # Timestamps du workflow
      t.datetime :sent_at
      t.datetime :viewed_at
      t.datetime :signed_at
      t.datetime :rejected_at

      # Données de signature
      t.json :signature_data
      t.text :rejection_reason

      # Validation technique
      t.json :technical_requirements
      t.integer :compliance_score

      t.timestamps
    end

    add_index :contractor_signatures, :signature_token, unique: true
    add_index :contractor_signatures, :contractor_email
    add_index :contractor_signatures, [:request_id, :status]
    add_index :contractor_signatures, :expiry_date
  end
end
