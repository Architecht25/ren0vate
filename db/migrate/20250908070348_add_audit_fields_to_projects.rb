class AddAuditFieldsToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :numero_audit, :string
    add_column :projects, :date_audit, :date
    add_column :projects, :numero_agrement_auditeur, :string
  end
end
