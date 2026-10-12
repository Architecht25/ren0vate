class AddCurrentVersionToProjectDocuments < ActiveRecord::Migration[8.1]
  def change
    add_reference :project_documents, :current_version, null: true, foreign_key: { to_table: :project_document_versions }
  end
end
