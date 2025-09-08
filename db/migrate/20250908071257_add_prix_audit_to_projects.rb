class AddPrixAuditToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :prix_audit, :decimal, precision: 10, scale: 2
  end
end
