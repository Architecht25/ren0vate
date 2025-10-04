class AddFormFieldsToRequestProgresses < ActiveRecord::Migration[8.0]
  def change
    add_column :request_progresses, :form_type, :string
    add_column :request_progresses, :form_name, :string

    # Rendre prime_id optionnel pour permettre la sélection par formulaire
    change_column_null :request_progresses, :prime_id, true
  end
end
