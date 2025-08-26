class CreateBceDenominations < ActiveRecord::Migration[8.0]
  def change
    create_table :bce_denominations do |t|
      t.string :entity_number, null: false
      t.string :language
      t.string :type_of_denomination
      t.text :denomination
      
      t.timestamps
      
      t.index :entity_number
      t.index :type_of_denomination
    end
  end
end
