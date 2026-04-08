class AddVisionAnalysisToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :vision_analysis, :jsonb
    add_column :projects, :vision_analysed_at, :datetime
  end
end
