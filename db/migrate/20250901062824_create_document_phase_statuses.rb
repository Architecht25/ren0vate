class CreateDocumentPhaseStatuses < ActiveRecord::Migration[8.0]
  def change
    create_table :document_phase_statuses do |t|
      t.references :property, null: false, foreign_key: true
      t.references :document_phase, null: false, foreign_key: true
      t.integer :completion_percentage, default: 0
      t.integer :status, default: 0  # 0 = not_started
      t.datetime :validated_at
      t.references :validated_by, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :document_phase_statuses, [:property_id, :document_phase_id],
              unique: true, name: 'index_phase_statuses_on_property_and_phase'
    add_index :document_phase_statuses, :status
  end
end
