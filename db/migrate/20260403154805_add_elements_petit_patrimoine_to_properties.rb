class AddElementsPetitPatrimoineToProperties < ActiveRecord::Migration[8.0]
  def change
    add_column :properties, :elements_petit_patrimoine, :text
  end
end
