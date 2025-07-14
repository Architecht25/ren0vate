class CreatePrimeSubmissions < ActiveRecord::Migration[8.0]
  def change
    create_table :prime_submissions do |t|
      t.references :property, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :dossier_number
      t.integer :region
      t.integer :status
      t.text :form_data
      t.string :admin_reference
      t.string :admin_status
      t.text :admin_response_data
      t.datetime :submitted_at

      t.timestamps
    end
  end
end
