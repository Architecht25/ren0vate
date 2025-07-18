class AddSimulationStepsToSimulations < ActiveRecord::Migration[8.0]
  def change
    add_column :simulations, :eligible, :boolean
    add_column :simulations, :category, :string
    add_column :simulations, :category_description, :text
    add_column :simulations, :ineligibility_reason, :text
  end
end
