require "test_helper"

class BudgetLineTest < ActiveSupport::TestCase
  fixtures :users, :properties, :projects

  test "budget_summary compare le prévisionnel du lot au devisé accepté" do
    project = projects(:one)
    toiture = project.lots.create!(key: "toiture", name: "Toiture", position: 0)
    project.budget_lines.create!(lot: toiture, label: "Toiture — prévisionnel initial", montant_prevu: 6000)

    accepted_quote = project.project_quotes.create!(
      entreprise_nom: "Couvreur SA", lot: toiture, status: "accepte",
      lines_attributes: [{ description: "Pose", quantite: 1, unite: "forfait", prix_unitaire_ht: 5000 }]
    )
    project.project_quotes.create!(
      entreprise_nom: "Devis refusé", lot: toiture, status: "refuse",
      lines_attributes: [{ description: "Pose", quantite: 1, unite: "forfait", prix_unitaire_ht: 9000 }]
    )

    summary = toiture.budget_summary
    assert_equal 6000, summary[:prevu]
    assert_equal accepted_quote.montant_ttc, summary[:devise]
  end
end
