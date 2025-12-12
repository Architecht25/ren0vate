class RemoveValidationFieldsFromProjects < ActiveRecord::Migration[8.0]
  def change
    remove_column :projects, :validation_status, :string
    remove_column :projects, :validation_score, :integer
    remove_column :projects, :last_validation_at, :datetime
  end
end
