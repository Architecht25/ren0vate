class AddEligibilityFieldsToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :bce_number, :string
    add_column :projects, :invoice_date, :date
    add_column :projects, :work_completion_date, :date
  end
end
