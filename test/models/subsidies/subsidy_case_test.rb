require "test_helper"

# Note : recalculate! évalue TOUTES les règles actives de la région, y
# compris celles déjà en base (seed initial du Lot 3). Les assertions
# portent sur le résultat de @rule spécifiquement, jamais sur le nombre
# total de résultats — pour ne pas dépendre du nombre de règles seedées.
class SubsidyCaseTest < ActiveSupport::TestCase
  fixtures :users

  setup do
    @user = users(:freemium_user)
    @key = "rule_#{SecureRandom.hex(4)}"
    @rule = SubsidyRule.create!(
      region: "wallonie", key: @key, label: "Règle test", valid_from: Date.new(2026, 1, 1),
      conditions: [{ "field" => "property.age_years", "operator" => "gte", "value" => 15 }],
      amount_formula: { "type" => "flat", "amount" => 1500 }
    )
  end

  def result_for(subsidy_case, rule = @rule)
    subsidy_case.latest_results.find { |r| r.subsidy_rule_id == rule.id }
  end

  test "recalculate! crée un résultat pour la règle de test, avec le bon montant" do
    subsidy_case = SubsidyCase.create!(region: "wallonie", mode: "simulation", user: @user, input_data: { "property" => { "age_years" => 20 } })

    subsidy_case.recalculate!

    result = result_for(subsidy_case)
    assert result.present?
    assert result.eligible
    assert_equal 1500, result.amount_estimated
  end

  test "un recalcul crée une nouvelle ligne au lieu d'écraser l'ancienne — l'historique est préservé" do
    subsidy_case = SubsidyCase.create!(region: "wallonie", mode: "simulation", user: @user, input_data: { "property" => { "age_years" => 5 } })
    subsidy_case.recalculate!
    assert_not result_for(subsidy_case).eligible

    subsidy_case.update!(input_data: { "property" => { "age_years" => 20 } })
    subsidy_case.recalculate!

    assert_equal 2, subsidy_case.subsidy_case_results.where(subsidy_rule: @rule).count
    assert result_for(subsidy_case).eligible
  end

  test "un résultat ne peut pas être modifié après création" do
    subsidy_case = SubsidyCase.create!(region: "wallonie", mode: "simulation", user: @user, input_data: {})
    subsidy_case.recalculate!
    result = subsidy_case.subsidy_case_results.first

    assert_raises(ActiveRecord::ReadOnlyRecord) { result.update!(eligible: true) }
  end

  test "total_estimated_amount inclut le montant de la règle de test quand elle est éligible" do
    subsidy_case = SubsidyCase.create!(region: "wallonie", mode: "simulation", user: @user, input_data: { "property" => { "age_years" => 20 } })
    subsidy_case.recalculate!
    assert subsidy_case.total_estimated_amount >= 1500
  end

  test "le mode dossier exige un projet" do
    subsidy_case = SubsidyCase.new(region: "wallonie", mode: "dossier", user: @user)
    assert_not subsidy_case.valid?
  end
end
