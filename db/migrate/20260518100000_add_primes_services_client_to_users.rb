class AddPrimesServicesClientToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :primes_services_client, :boolean, default: false, null: false
    add_index  :users, :primes_services_client
  end
end
