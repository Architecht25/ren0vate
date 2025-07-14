class AddAuditEnergetiqueToProperties < ActiveRecord::Migration[8.0]
  def change
    add_column :properties, :audit_energetique, :boolean
  end
end
