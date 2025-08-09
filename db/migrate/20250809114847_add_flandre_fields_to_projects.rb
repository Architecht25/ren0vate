class AddFlandreFieldsToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :type_travaux, :text
    add_column :projects, :reconstruction_demolition, :boolean
    add_column :projects, :tva_reduit_6_pourcent, :boolean
  end
end
