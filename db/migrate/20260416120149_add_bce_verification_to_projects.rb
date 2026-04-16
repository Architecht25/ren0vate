class AddBceVerificationToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :entrepreneur_bce_verifie_at, :datetime
    add_column :projects, :entrepreneur_bce_statut, :string
  end
end
