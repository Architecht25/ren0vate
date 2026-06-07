class AddLeaseIdToDocuments < ActiveRecord::Migration[8.1]
  def change
    add_column :documents, :lease_id, :bigint
    add_index :documents, :lease_id
  end
end
