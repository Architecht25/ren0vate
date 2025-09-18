class AddFormFieldsToRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :requests, :form_type, :string
    add_column :requests, :form_data, :jsonb, default: {}
    add_column :requests, :template_version, :string, default: '1.0'

    add_index :requests, :form_type
    add_index :requests, :form_data, using: :gin
  end
end
