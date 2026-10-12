require "test_helper"

module Subsidies
  class RuleEngineTest < ActiveSupport::TestCase
    FakeRule = Struct.new(:conditions, :amount_formula)

    test "éligible quand toutes les conditions sont satisfaites, montant calculé en pourcentage plafonné" do
      rule = FakeRule.new(
        [{ "field" => "property.age_years", "operator" => "gte", "value" => 15 }],
        { "type" => "percentage", "base_field" => "travaux.montant_ttc", "rate" => 25, "max" => 2500 }
      )
      engine = RuleEngine.new({ "property" => { "age_years" => 20 }, "travaux" => { "montant_ttc" => 20_000 } })

      result = engine.evaluate(rule)

      assert result[:eligible]
      assert_equal 2500, result[:amount] # 25% de 20 000 = 5000, plafonné à 2500
      assert_equal [], result[:reasons]
    end

    test "inéligible dès qu'une condition échoue, avec la raison associée" do
      rule = FakeRule.new(
        [
          { "field" => "property.age_years", "operator" => "gte", "value" => 15 },
          { "field" => "household.is_owner", "operator" => "eq", "value" => true }
        ],
        { "type" => "flat", "amount" => 1000 }
      )
      engine = RuleEngine.new({ "property" => { "age_years" => 5 }, "household" => { "is_owner" => true } })

      result = engine.evaluate(rule)

      assert_not result[:eligible]
      assert_nil result[:amount]
      assert_equal 1, result[:reasons].length
      assert_equal "property.age_years", result[:reasons].first["field"]
    end

    test "formule per_unit multiplie la quantité par le prix unitaire, sans plafond si absent" do
      rule = FakeRule.new([], { "type" => "per_unit", "quantity_field" => "travaux.surface_m2", "unit_amount" => 15 })
      engine = RuleEngine.new({ "travaux" => { "surface_m2" => 40 } })

      result = engine.evaluate(rule)
      assert_equal 600, result[:amount]
    end

    test "un champ absent de input_data rend la condition fausse sans lever d'exception" do
      rule = FakeRule.new([{ "field" => "property.inexistant", "operator" => "gte", "value" => 10 }], {})
      engine = RuleEngine.new({})

      result = engine.evaluate(rule)
      assert_not result[:eligible]
    end

    test "un opérateur inconnu lève ArgumentError" do
      rule = FakeRule.new([{ "field" => "x", "operator" => "nexiste_pas", "value" => 1 }], {})
      assert_raises(ArgumentError) { RuleEngine.new({}).evaluate(rule) }
    end
  end
end
