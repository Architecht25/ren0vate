require "test_helper"

class HouseholdIncomeCalculatorTest < ActiveSupport::TestCase
  fixtures :users

  setup do
    @user = users(:freemium_user)
  end

  def calculator(user: @user)
    Regions::Wallonie::HouseholdIncomeCalculator.new(user)
  end

  test "revenu total = revenu demandeur seul si célibataire" do
    @user.update!(revenu_demandeur: 30_000, situation_familiale: "celibataire")
    assert_equal 30_000, calculator.total_household_income
  end

  test "revenu total additionne le conjoint si marié" do
    @user.update!(revenu_demandeur: 30_000, revenu_conjoint: 10_000, situation_familiale: "marie")
    assert_equal 40_000, calculator.total_household_income
  end

  test "revenu ajusté déduit 5000€ par enfant" do
    @user.update!(revenu_demandeur: 40_000, situation_familiale: "celibataire", nombre_enfants: 2)
    assert_equal 30_000, calculator.adjusted_income
  end

  test "revenu ajusté ne descend jamais sous zéro" do
    @user.update!(revenu_demandeur: 5_000, situation_familiale: "celibataire", nombre_enfants: 3)
    assert_equal 0, calculator.adjusted_income
  end

  test "total_deductions reflète l'écart entre revenu total et ajusté" do
    @user.update!(revenu_demandeur: 40_000, situation_familiale: "celibataire", nombre_enfants: 1)
    assert_equal 5_000, calculator.total_deductions
  end
end
