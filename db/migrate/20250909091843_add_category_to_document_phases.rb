class AddCategoryToDocumentPhases < ActiveRecord::Migration[8.0]
  def change
    add_column :document_phases, :category, :string, default: 'chantier', null: false, comment: 'Type de projet: chantier ou investissement'
    add_index :document_phases, :category
  end
end
