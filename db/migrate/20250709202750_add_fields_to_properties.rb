class AddFieldsToProperties < ActiveRecord::Migration[8.0]
  def change
    add_column :properties, :rue, :string
    add_column :properties, :numero, :string
    add_column :properties, :code_postal, :string
    add_column :properties, :commune, :string
    add_column :properties, :region, :string
    add_column :properties, :type_propriete, :string
    add_column :properties, :type, :string
    add_column :properties, :occupation, :string
    add_column :properties, :autre_bien, :string
    add_column :properties, :peb, :string
    add_column :properties, :annee_construction, :integer
    add_column :properties, :date_raccordement_electrique, :integer
    add_column :properties, :numero_ean, :string
    add_column :properties, :numero_cadastre, :string
  end
end
