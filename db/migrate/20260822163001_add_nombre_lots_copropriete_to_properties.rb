class AddNombreLotsCoproprieteToProperties < ActiveRecord::Migration[8.1]
  def change
    add_column :properties, :nombre_lots_copropriete, :integer
  end
end
