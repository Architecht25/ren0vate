class AddPermisUrbanismeStatutToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :permis_urbanisme_statut, :string
    add_column :projects, :permis_urbanisme_autorite, :string
    add_column :projects, :permis_urbanisme_notes, :text
  end
end
