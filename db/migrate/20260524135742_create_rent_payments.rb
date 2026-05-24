class CreateRentPayments < ActiveRecord::Migration[8.1]
  def change
    create_table :rent_payments do |t|
      t.references :lease, null: false, foreign_key: true
      t.date :due_date, null: false
      t.date :paid_date
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :status, null: false, default: 'pending'
      t.string :payment_method
      t.text :notes

      t.timestamps
    end
    add_index :rent_payments, :status
    add_index :rent_payments, :due_date
  end
end
