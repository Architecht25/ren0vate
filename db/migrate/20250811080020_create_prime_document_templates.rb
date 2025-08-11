class CreatePrimeDocumentTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :prime_document_templates do |t|
      t.string :title
      t.text :description
      t.string :type_document
      t.references :prime, null: false, foreign_key: true
      t.boolean :is_required
      t.string :file_url
      t.integer :order_position

      t.timestamps
    end
  end
end
