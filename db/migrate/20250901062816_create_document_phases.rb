class CreateDocumentPhases < ActiveRecord::Migration[8.0]
  def change
    create_table :document_phases do |t|
      t.string :name, null: false
      t.text :description, null: false
      t.string :icon, null: false
      t.string :color, null: false
      t.integer :position, null: false
      t.json :required_document_types, default: []
      t.json :optional_document_types, default: []

      t.timestamps
    end

    add_index :document_phases, :name, unique: true
    add_index :document_phases, :position, unique: true
  end
end
