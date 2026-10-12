require "test_helper"

# Vérifie le mode "dossier" du moteur de primes (cahier des charges §9 :
# recalculé à chaque changement de devis réel) — pas un test de policy ou
# de modèle unique, placé à la racine de test/models pour cette raison.
class ProjectQuoteSubsidySyncTest < ActiveSupport::TestCase
  fixtures :users, :properties, :projects

  test "accepter un devis déclenche le recalcul du dossier de primes du chantier" do
    project = projects(:one)
    project.property.update!(region: "wallonie", rue: "Rue de la Loi", numero: "1", code_postal: "1000", commune: "Bruxelles")
    SubsidyRule.create!(region: "wallonie", key: "rule_sync_#{SecureRandom.hex(4)}", label: "Règle test", valid_from: Date.new(2026, 1, 1))

    quote = project.project_quotes.create!(
      entreprise_nom: "Couvreur SA",
      lines_attributes: [{ description: "Isolation", quantite: 1, unite: "forfait", prix_unitaire_ht: 8000 }]
    )

    assert_nil project.subsidy_cases.find_by(mode: "dossier")

    quote.update!(status: "envoye")
    assert_nil project.subsidy_cases.find_by(mode: "dossier"), "pas de recalcul avant acceptation"

    quote.update!(status: "accepte")

    dossier_case = project.subsidy_cases.find_by(mode: "dossier")
    assert dossier_case.present?
    assert_equal quote.montant_ttc, dossier_case.input_data["travaux"]["montant_ttc"].to_f
    assert dossier_case.subsidy_case_results.any?
  end
end
