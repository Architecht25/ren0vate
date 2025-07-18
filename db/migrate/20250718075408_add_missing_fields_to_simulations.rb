class AddMissingFieldsToSimulations < ActiveRecord::Migration[8.0]
  def change
    add_column :simulations, :titre, :string
    add_column :simulations, :region, :string
    add_column :simulations, :parameters, :text
    add_column :simulations, :source, :string
  end
end
