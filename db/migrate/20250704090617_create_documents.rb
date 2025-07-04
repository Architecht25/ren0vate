class CreateDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :documents do |t|
      t.references :user, null: false, foreign_key: true
      t.references :property, null: false, foreign_key: true
      t.references :request, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.references :simulation, null: false, foreign_key: true
      t.string :type_document
      t.string :file_url
      t.string :status
      t.text :notes
      t.string :document_source

      t.timestamps
    end
  end
end
