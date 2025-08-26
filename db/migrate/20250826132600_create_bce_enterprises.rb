class CreateBceEnterprises < ActiveRecord::Migration[8.0]
  def change
    create_table :bce_enterprises do |t|
      t.string :enterprise_number, null: false, index: { unique: true }
      t.string :status
      t.string :juridical_situation
      t.string :type_of_enterprise
      t.string :juridical_form
      t.string :juridical_form_cac
      t.date :start_date
      
      t.timestamps
      
      t.index :status
      t.index :juridical_form
      t.index :enterprise_number, unique: true
    end
  end
end
