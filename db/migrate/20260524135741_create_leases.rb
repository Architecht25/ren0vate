class CreateLeases < ActiveRecord::Migration[8.1]
  def change
    create_table :leases do |t|
      t.references :property, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: true
      t.string :lease_type, null: false, default: 'residence_principale'
      t.date :start_date, null: false
      t.date :end_date
      t.decimal :rent_amount, precision: 10, scale: 2, null: false
      t.decimal :charges_amount, precision: 10, scale: 2, default: 0
      t.decimal :rental_guarantee_amount, precision: 10, scale: 2
      t.integer :indexation_month, default: 1  # mois d'indexation annuelle (1=janvier)
      t.string :status, null: false, default: 'actif'
      t.date :notice_given_at
      t.string :notice_by  # locataire / propriétaire
      t.text :notes

      t.timestamps
    end
    add_index :leases, :status
  end
end
