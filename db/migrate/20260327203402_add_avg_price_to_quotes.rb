class AddAvgPriceToQuotes < ActiveRecord::Migration[8.0]
  def change
    add_column :quote_items, :unit_price_avg, :decimal, precision: 10, scale: 2
    add_column :quote_items, :total_avg, :decimal, precision: 10, scale: 2
  end
end
