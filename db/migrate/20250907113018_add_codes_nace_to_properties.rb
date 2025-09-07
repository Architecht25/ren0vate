class AddCodesNaceToProperties < ActiveRecord::Migration[8.0]
  def change
    add_column :properties, :code_nace_1, :string
    add_column :properties, :code_nace_2, :string
    add_column :properties, :code_nace_3, :string
    add_column :properties, :code_nace_4, :string
    add_column :properties, :code_nace_5, :string
  end
end
