require "test_helper"

# Suite de référence par région (cahier des charges V2 §9 : "cas types avec
# résultat attendu, vérifiés à chaque modification des règles").
#
# IMPORTANT : les règles sont recréées ici en `setup`, pas lues depuis les
# données insérées par db/migrate/20261012140100_seed_initial_subsidy_rules.rb
# — `db:schema:load`/`db:test:prepare` (utilisés par la CI, voir
# .github/workflows/ci.yml) reconstruisent la base depuis db/schema.rb et
# n'exécutent PAS le code Ruby `up` des migrations déjà marquées comme
# appliquées, donc pas les INSERT qu'il contient. Garder les conditions
# exactement synchronisées avec la migration ci-dessus si elle change.
class SubsidySimulationsSmokeTest < ActionDispatch::IntegrationTest
  setup do
    @wallonie_rule = SubsidyRule.create!(
      region: "wallonie", key: "primes_renovation_generale", label: "Primes rénovation (régime cash, Wallonie)",
      valid_from: Date.new(2026, 1, 1),
      conditions: [
        { "field" => "property.region", "operator" => "eq", "value" => "wallonie" },
        { "field" => "property.habitation_percentage", "operator" => "gte", "value" => 50 },
        { "field" => "household.is_owner", "operator" => "eq", "value" => true },
        { "field" => "property.is_main_residence", "operator" => "eq", "value" => true },
        { "field" => "property.age_years", "operator" => "gte", "value" => 15 }
      ],
      amount_formula: { "type" => "percentage", "base_field" => "travaux.montant_ttc", "rate" => 25, "max" => 2500 }
    )

    @flandre_rule = SubsidyRule.create!(
      region: "flandre", key: "mijn_verbouwpremie", label: "Mijn VerbouwPremie (Flandre)",
      valid_from: Date.new(2026, 3, 1),
      conditions: [
        { "field" => "property.habitation_percentage", "operator" => "eq", "value" => 100 },
        { "field" => "household.ownership_percentage", "operator" => "gte", "value" => 1 },
        { "field" => "property.year_built", "operator" => "lt", "value" => 2006 }
      ],
      amount_formula: { "type" => "percentage", "base_field" => "travaux.montant_ttc", "rate" => 20, "max" => 3000 }
    )
  end

  # Routes désactivées avant déploiement prod du 12/10/2026 (voir
  # config/routes/subsidy_simulations.rb) — montants SubsidyRule non
  # vérifiés avec le barème officiel. Les 2 tests qui passaient par les
  # routes publiques sont donc skip ; le moteur lui-même (recalculate!,
  # éligibilité par région) reste couvert ci-dessous, sans passer par HTTP.
  test "new s'affiche sans authentification" do
    skip "route désactivée avant déploiement prod — voir config/routes/subsidy_simulations.rb"
    get new_subsidy_simulation_path(locale: :fr)
    assert_response :success
  end

  test "Wallonie — un ménage propriétaire, résidence principale, bien de 20 ans est éligible" do
    skip "route désactivée avant déploiement prod — voir config/routes/subsidy_simulations.rb"
    post subsidy_simulations_path(locale: :fr), params: {
      region: "wallonie",
      input_data: {
        property: { habitation_percentage: 100, age_years: 20, is_main_residence: "true" },
        household: { is_owner: "true" },
        travaux: { montant_ttc: 10_000 }
      }
    }

    subsidy_case = SubsidyCase.last
    assert_redirected_to subsidy_simulation_path(subsidy_case, locale: :fr)

    follow_redirect!
    assert_response :success

    result = subsidy_case.latest_results.find { |r| r.subsidy_rule_id == @wallonie_rule.id }
    assert result.eligible, "devrait être éligible : propriétaire, résidence principale, bien de 20 ans"
    assert_equal 2500, result.amount_estimated # 25% de 10 000 = 2500, dans le plafond
  end

  test "Wallonie — un bien trop récent (moins de 15 ans) est inéligible" do
    subsidy_case = SubsidyCase.create!(
      region: "wallonie", mode: "simulation",
      input_data: { property: { region: "wallonie", habitation_percentage: 100, age_years: 5, is_main_residence: true }, household: { is_owner: true } }
    )
    subsidy_case.recalculate!

    result = subsidy_case.latest_results.find { |r| r.subsidy_rule_id == @wallonie_rule.id }
    assert_not result.eligible
    assert_includes result.reasons.map { |r| r["field"] }, "property.age_years"
  end

  test "Flandre — bien 100% résidentiel construit avant 2006 est éligible" do
    subsidy_case = SubsidyCase.create!(
      region: "flandre", mode: "simulation",
      input_data: { property: { habitation_percentage: 100, year_built: 1980 }, household: { ownership_percentage: 100 } }
    )
    subsidy_case.recalculate!

    result = subsidy_case.latest_results.find { |r| r.subsidy_rule_id == @flandre_rule.id }
    assert result.eligible
  end

  test "Flandre — bien construit après 2006 est inéligible (réforme résidentiel exclusif incluse)" do
    subsidy_case = SubsidyCase.create!(
      region: "flandre", mode: "simulation",
      input_data: { property: { habitation_percentage: 100, year_built: 2015 }, household: { ownership_percentage: 100 } }
    )
    subsidy_case.recalculate!

    result = subsidy_case.latest_results.find { |r| r.subsidy_rule_id == @flandre_rule.id }
    assert_not result.eligible
  end

  test "Bruxelles — aucune règle générale active, la simulation retourne zéro résultat (Renolution supprimé)" do
    subsidy_case = SubsidyCase.create!(region: "bruxelles", mode: "simulation", input_data: {})
    subsidy_case.recalculate!

    assert_equal [], subsidy_case.latest_results.to_a
    assert_equal 0, subsidy_case.total_estimated_amount
  end
end
