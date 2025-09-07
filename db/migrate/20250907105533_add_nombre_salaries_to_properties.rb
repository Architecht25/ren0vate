class AddNombreSalariesToProperties < ActiveRecord::Migration[8.0]
  def change
    add_column :properties, :nombre_salaries, :integer
  end
end
