class CreateQuotes < ActiveRecord::Migration[8.0]
  def change
    create_table :quotes do |t|
      t.references :property, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.decimal :total_min, precision: 10, scale: 2
      t.decimal :total_max, precision: 10, scale: 2
      t.integer :duration_min_days
      t.integer :duration_max_days
      t.string :status, default: 'draft', null: false

      t.timestamps
    end
  end
end
