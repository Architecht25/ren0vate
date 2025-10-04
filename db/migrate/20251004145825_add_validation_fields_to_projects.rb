class AddValidationFieldsToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :validation_status, :string
    add_column :projects, :validation_score, :integer
    add_column :projects, :last_validation_at, :datetime
  end
end
