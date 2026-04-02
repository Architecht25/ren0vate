class DropPrimeDocumentTemplates < ActiveRecord::Migration[8.0]
  def up
    remove_foreign_key :prime_document_templates, :primes
    drop_table :prime_document_templates
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
