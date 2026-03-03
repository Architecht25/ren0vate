class RemoveRenolutionAndInvestmentColumnsFromSimulations < ActiveRecord::Migration[8.0]
  def change
    # Suppression des colonnes liées aux fonctionnalités RENOLUTION/Investment obsolètes
    remove_column :simulations, :eligible_investment, :boolean
    remove_column :simulations, :investment_ineligibility_reason, :text
    remove_column :simulations, :eligible_renolution, :boolean
    remove_column :simulations, :renolution_ineligibility_reason, :text
  end
end
