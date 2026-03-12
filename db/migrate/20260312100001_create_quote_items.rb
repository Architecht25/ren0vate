class CreateQuoteItems < ActiveRecord::Migration[8.0]
  def change
    create_table :quote_items do |t|
      t.references :quote, null: false, foreign_key: true
      t.string :work_type_key, null: false
      t.decimal :quantity, precision: 10, scale: 2, null: false
      t.string :unit, null: false
      t.decimal :unit_price_min, precision: 10, scale: 2
      t.decimal :unit_price_max, precision: 10, scale: 2
      t.decimal :total_min, precision: 10, scale: 2
      t.decimal :total_max, precision: 10, scale: 2
      t.jsonb :options, default: {}

      t.timestamps
    end
  end
end
