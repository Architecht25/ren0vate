class AddMissingFlandreFieldsToProperties < ActiveRecord::Migration[8.0]
  def change
    add_column :properties, :type_propriete_flandre, :string
    add_column :properties, :pourcentage_propriete, :integer
    add_column :properties, :domicilie_flandre, :boolean
    add_column :properties, :client_protege_flandre, :boolean
  end
end
