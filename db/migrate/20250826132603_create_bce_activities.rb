class CreateBceActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :bce_activities do |t|
      t.string :entity_number, null: false
      t.string :activity_group
      t.string :nace_version
      t.string :nace_code
      t.string :classification
      
      t.timestamps
      
      t.index :entity_number
      t.index :nace_code
      t.index :classification
    end
  end
end
