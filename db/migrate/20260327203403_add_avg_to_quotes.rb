class AddAvgToQuotes < ActiveRecord::Migration[8.0]
  def change
    add_column :quotes, :total_avg, :decimal, precision: 10, scale: 2
    add_column :quotes, :duration_avg_days, :integer
  end
end
