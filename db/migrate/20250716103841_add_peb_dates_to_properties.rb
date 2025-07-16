class AddPebDatesToProperties < ActiveRecord::Migration[8.0]
  def change
    add_column :properties, :date_peb_avant_travaux, :date
    add_column :properties, :date_peb_apres_travaux, :date
  end
end
