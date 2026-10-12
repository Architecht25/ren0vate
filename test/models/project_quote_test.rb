require "test_helper"

class ProjectQuoteTest < ActiveSupport::TestCase
  fixtures :users, :properties, :projects

  setup do
    @owner = users(:freemium_user)
    @project = projects(:one)
  end

  test "les totaux sont recalculés depuis les lignes, jamais saisis directement" do
    quote = @project.project_quotes.create!(
      entreprise_nom: "Toitures Dupont",
      lines_attributes: [
        { description: "Démontage ancienne toiture", quantite: 1, unite: "forfait", prix_unitaire_ht: 1000 },
        { description: "Pose nouvelle couverture", quantite: 50, unite: "m2", prix_unitaire_ht: 80 }
      ]
    )

    assert_equal 5000, quote.montant_ht # 1000 + 50*80
    assert_equal 1050, quote.montant_tva # 21%
    assert_equal 6050, quote.montant_ttc
  end

  test "un devis ne peut pas être rattaché à un lot d'un autre chantier" do
    other_project = Project.create!(user: @owner, property: properties(:one), nom: "Autre chantier")
    foreign_lot = other_project.lots.first

    quote = @project.project_quotes.build(entreprise_nom: "X", lot: foreign_lot)
    assert_not quote.valid?
  end
end
