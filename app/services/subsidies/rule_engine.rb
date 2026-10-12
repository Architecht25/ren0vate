# V2 — Lot 3 : évaluateur générique d'une SubsidyRule contre un input_data
# structuré (cahier des charges §9). Aucun `eval`/code dynamique — les
# conditions et la formule de montant sont une petite DSL JSON fermée
# (voir OPERATORS et les types de #compute_amount), volontairement limitée
# pour rester éditable sans risque depuis une future interface
# d'administration, sans jamais exécuter de code arbitraire.
module Subsidies
  class RuleEngine
    # Les formulaires HTML ne soumettent que des chaînes ("true"/"false") —
    # sans cette normalisation, une condition `{"operator":"eq","value":true}`
    # ne matcherait jamais une valeur saisie via un <select>, puisque "true"
    # (String) != true (Boolean) en Ruby.
    BOOLEAN_STRINGS = { "true" => true, "false" => false }.freeze
    NORMALIZE = ->(value) { BOOLEAN_STRINGS.fetch(value, value) }

    OPERATORS = {
      "eq" => ->(actual, expected) { NORMALIZE.call(actual) == NORMALIZE.call(expected) },
      "gte" => ->(actual, expected) { actual.present? && actual.to_f >= expected.to_f },
      "lte" => ->(actual, expected) { actual.present? && actual.to_f <= expected.to_f },
      "gt" => ->(actual, expected) { actual.present? && actual.to_f > expected.to_f },
      "lt" => ->(actual, expected) { actual.present? && actual.to_f < expected.to_f },
      "in" => ->(actual, expected) { Array(expected).map { |v| NORMALIZE.call(v) }.include?(NORMALIZE.call(actual)) },
      "present" => ->(actual, _expected) { actual.present? }
    }.freeze

    def initialize(input_data)
      @input_data = (input_data || {}).deep_stringify_keys
    end

    # Retourne { eligible:, amount:, reasons: } — reasons liste les
    # conditions non satisfaites (vide si éligible), toujours en référence
    # au résultat affiché à l'utilisateur (cahier des charges §9 :
    # "affiche ses hypothèses").
    def evaluate(rule)
      reasons = []

      eligible = Array(rule.conditions).all? do |condition|
        met = check_condition(condition)
        reasons << condition.merge("met" => false) unless met
        met
      end

      { eligible: eligible, amount: eligible ? compute_amount(rule.amount_formula) : nil, reasons: reasons }
    end

    private

    def check_condition(condition)
      comparator = OPERATORS.fetch(condition["operator"]) { raise ArgumentError, "opérateur inconnu : #{condition['operator']}" }
      comparator.call(fetch_field(condition["field"]), condition["value"])
    rescue ArgumentError
      raise
    rescue StandardError
      false
    end

    def fetch_field(path)
      path.to_s.split(".").reduce(@input_data) { |acc, key| acc.is_a?(Hash) ? acc[key] : nil }
    end

    def compute_amount(formula)
      return nil if formula.blank?

      amount = case formula["type"]
      when "flat"
        formula["amount"].to_f
      when "percentage"
        base = fetch_field(formula["base_field"]).to_f
        base * (formula["rate"].to_f / 100.0)
      when "per_unit"
        fetch_field(formula["quantity_field"]).to_f * formula["unit_amount"].to_f
      end

      return nil if amount.nil?
      cap = formula["max"]
      amount = [amount, cap.to_f].min if cap.present?
      amount.round(2)
    end
  end
end
