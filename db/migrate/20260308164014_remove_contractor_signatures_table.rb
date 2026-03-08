class RemoveContractorSignaturesTable < ActiveRecord::Migration[8.0]
  def change
    # Suppression de la table contractor_signatures
    # Cette fonctionnalité n'a jamais été implémentée complètement :
    # - Pas de modèle dans app/models
    # - Pas de contrôleur
    # - Mailer jamais utilisé
    # - Fonctionnalité abandonnée

    drop_table :contractor_signatures, if_exists: true do |t|
      t.bigint "request_id", null: false
      t.bigint "user_id"
      t.string "contractor_name", null: false
      t.string "contractor_email", null: false
      t.string "contractor_phone", null: false
      t.string "contractor_company"
      t.string "contractor_registration_number"
      t.text "work_description", null: false
      t.string "work_type", null: false
      t.decimal "estimated_amount", precision: 10, scale: 2
      t.string "status", default: "pending", null: false
      t.string "signature_token", null: false
      t.date "expiry_date"
      t.datetime "sent_at"
      t.datetime "viewed_at"
      t.datetime "signed_at"
      t.datetime "rejected_at"
      t.json "signature_data"
      t.text "rejection_reason"
      t.json "technical_requirements"
      t.integer "compliance_score"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["contractor_email"], name: "index_contractor_signatures_on_contractor_email"
      t.index ["expiry_date"], name: "index_contractor_signatures_on_expiry_date"
      t.index ["request_id", "status"], name: "index_contractor_signatures_on_request_id_and_status"
      t.index ["request_id"], name: "index_contractor_signatures_on_request_id"
      t.index ["signature_token"], name: "index_contractor_signatures_on_signature_token", unique: true
      t.index ["user_id"], name: "index_contractor_signatures_on_user_id"
    end
  end
end
