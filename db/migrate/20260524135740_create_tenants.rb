class CreateTenants < ActiveRecord::Migration[8.1]
  def change
    create_table :tenants do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email
      t.string :phone
      t.text :national_number_ciphertext  # encrypted
      t.text :notes
      t.references :property, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
