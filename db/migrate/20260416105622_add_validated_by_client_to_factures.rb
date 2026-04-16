class AddValidatedByClientToFactures < ActiveRecord::Migration[8.0]
  def change
    add_column :factures, :validated_by_client_at, :datetime
    add_column :factures, :validated_by_client_id, :bigint
  end
end
