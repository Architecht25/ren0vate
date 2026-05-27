class CreateProjectNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :project_notes do |t|
      t.references :project, null: false, foreign_key: true
      t.text :content, null: false

      t.timestamps
    end

    add_index :project_notes, [:project_id, :created_at]
  end
end
