class AddCommunalFieldsToPrimeDocumentTemplates < ActiveRecord::Migration[8.0]
  def change
    add_column :prime_document_templates, :commune_name, :string
    add_column :prime_document_templates, :postal_codes, :text # JSON array des codes postaux
    add_column :prime_document_templates, :region, :string
    add_column :prime_document_templates, :external_url, :string
    add_column :prime_document_templates, :is_external_form, :boolean, default: false
    add_column :prime_document_templates, :contact_info, :text # JSON avec contact info

    add_index :prime_document_templates, :commune_name
    add_index :prime_document_templates, :region
  end
end
