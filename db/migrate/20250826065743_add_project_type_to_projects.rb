class AddProjectTypeToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :project_type, :string, default: 'renovation'

    # Mettre à jour tous les projets existants pour être des rénovations
    reversible do |dir|
      dir.up do
        execute "UPDATE projects SET project_type = 'renovation' WHERE project_type IS NULL"
      end
    end
  end
end
