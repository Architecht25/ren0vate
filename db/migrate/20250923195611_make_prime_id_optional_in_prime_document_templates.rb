class MakePrimeIdOptionalInPrimeDocumentTemplates < ActiveRecord::Migration[8.0]
  def change
    # Rendre la colonne prime_id optionnelle pour permettre des documents généraux
    change_column_null :prime_document_templates, :prime_id, true
  end
end
