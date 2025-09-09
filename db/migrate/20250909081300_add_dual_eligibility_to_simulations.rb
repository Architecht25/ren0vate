class AddDualEligibilityToSimulations < ActiveRecord::Migration[8.0]
  def change
    # Champs pour l'éligibilité aux investissements entreprise
    add_column :simulations, :eligible_investment, :boolean
    add_column :simulations, :investment_ineligibility_reason, :text

    # Champs pour l'éligibilité aux primes RENOLUTION
    add_column :simulations, :eligible_renolution, :boolean
    add_column :simulations, :renolution_ineligibility_reason, :text

    # Index pour les requêtes
    add_index :simulations, :eligible_investment
    add_index :simulations, :eligible_renolution

    # Commentaire pour clarification
    # Ces champs permettent de gérer la double éligibilité pour les projets à finalité économique
    # qui peuvent bénéficier à la fois des aides aux investissements ET des primes RENOLUTION
  end
end
