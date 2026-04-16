class AddPermisHistoriqueToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :permis_urbanisme_historique, :jsonb, default: [], null: false
  end
end
