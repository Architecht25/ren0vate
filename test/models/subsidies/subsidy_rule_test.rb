require "test_helper"

class SubsidyRuleTest < ActiveSupport::TestCase
  def valid_attrs(overrides = {})
    { region: "wallonie", key: "test_rule_#{SecureRandom.hex(4)}", label: "Règle de test", valid_from: Date.new(2026, 1, 1) }.merge(overrides)
  end

  test "deux versions successives (sans chevauchement) sont valides" do
    key = "rule_#{SecureRandom.hex(4)}"
    first = SubsidyRule.create!(valid_attrs(key: key, valid_from: Date.new(2026, 1, 1), valid_to: Date.new(2026, 6, 1)))
    second = SubsidyRule.create!(valid_attrs(key: key, valid_from: Date.new(2026, 6, 1)))

    assert first.persisted?
    assert second.persisted?
  end

  test "deux versions qui se chevauchent sont rejetées" do
    key = "rule_#{SecureRandom.hex(4)}"
    SubsidyRule.create!(valid_attrs(key: key, valid_from: Date.new(2026, 1, 1)))

    overlapping = SubsidyRule.new(valid_attrs(key: key, valid_from: Date.new(2026, 3, 1)))
    assert_not overlapping.valid?
  end

  test "active_for_region respecte les dates de validité" do
    key = "rule_#{SecureRandom.hex(4)}"
    old_version = SubsidyRule.create!(valid_attrs(key: key, valid_from: Date.new(2020, 1, 1), valid_to: Date.new(2026, 1, 1)))
    new_version = SubsidyRule.create!(valid_attrs(key: key, valid_from: Date.new(2026, 1, 1)))

    assert_includes SubsidyRule.active_for_region("wallonie", date: Date.new(2022, 6, 1)), old_version
    assert_includes SubsidyRule.active_for_region("wallonie", date: Date.new(2026, 6, 1)), new_version
    assert_not_includes SubsidyRule.active_for_region("wallonie", date: Date.new(2026, 6, 1)), old_version
  end

  test "une réforme s'applique sans changer de code — changer valid_to puis insérer une nouvelle version suffit" do
    key = "rule_#{SecureRandom.hex(4)}"
    v1 = SubsidyRule.create!(valid_attrs(key: key, valid_from: Date.new(2026, 1, 1), amount_formula: { "type" => "flat", "amount" => 1000 }))

    # Réforme : on clôture v1 et on ouvre v2 avec un nouveau montant — aucune ligne de code modifiée.
    v1.update!(valid_to: Date.new(2026, 10, 1))
    v2 = SubsidyRule.create!(valid_attrs(key: key, valid_from: Date.new(2026, 10, 1), amount_formula: { "type" => "flat", "amount" => 2000 }))

    engine = Subsidies::RuleEngine.new({})
    assert_equal 1000, engine.evaluate(SubsidyRule.active(region: "wallonie", key: key, date: Date.new(2026, 5, 1)).first).dig(:amount)
    assert_equal 2000, engine.evaluate(SubsidyRule.active(region: "wallonie", key: key, date: Date.new(2026, 11, 1)).first).dig(:amount)
  end
end
