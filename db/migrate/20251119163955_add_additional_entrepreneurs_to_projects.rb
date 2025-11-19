class AddAdditionalEntrepreneursToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :additional_entrepreneurs, :text
  end
end
