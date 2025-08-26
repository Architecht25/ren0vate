class CreateBceAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :bce_addresses do |t|
      t.string :entity_number, null: false
      t.string :type_of_address
      t.string :country_nl
      t.string :country_fr
      t.string :zipcode
      t.string :municipality_nl
      t.string :municipality_fr
      t.string :street_nl
      t.string :street_fr
      t.string :house_number
      t.string :box
      t.text :extra_address_info
      t.date :date_striking_off
      
      t.timestamps
      
      t.index :entity_number
      t.index :type_of_address
      t.index :zipcode
    end
  end
end
