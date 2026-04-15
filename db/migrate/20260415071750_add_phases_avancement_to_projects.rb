class AddPhasesAvancementToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :phases_avancement, :jsonb, default: {}, null: false
  end
end
