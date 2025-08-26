class CreateBceEnterprises < ActiveRecord::Migration[8.0]
  def change
    create_table :bce_enterprises do |t|
      t.string :enterprise_number, null: false, index: { unique: true }
      t.string :status_code
      t.string :juridical_situation
      t.string :type_of_enterprise
      t.string :juridical_form
      t.date :start_date

      t.timestamps
    end

    add_index :bce_enterprises, :status_code
    add_index :bce_enterprises, :juridical_form
  end
end
