class AddHabitationPercentageToProperties < ActiveRecord::Migration[8.0]
  def change
    add_column :properties, :habitation_percentage, :integer
  end
end
