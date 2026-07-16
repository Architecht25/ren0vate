require "test_helper"

class PretReductionCalculatorServiceTest < ActiveSupport::TestCase
  fixtures :users

  setup do
    @user = users(:freemium_user)
    @user.update!(situation_familiale: "celibataire", nombre_enfants: 0, revenu_demandeur: 28_900)
  end

  def calculate(montant_projet)
    Regions::Wallonie::PretReduction::CalculatorService.new(@user, montant_projet: montant_projet).calculate
  end

  test "réduction = montant projet x taux quand sous le plafond" do
    result = calculate(20_000)
    assert_equal 20_000, result[:montant_projet_retenu]
    assert_equal 0.50, result[:taux_reduction]
    assert_equal 10_000.0, result[:reduction_solde]
  end

  test "montant projet plafonné à 75 000€" do
    result = calculate(90_000)
    assert_equal 75_000, result[:montant_projet_retenu]
    assert_equal 37_500.0, result[:reduction_solde]
  end

  test "réduction nulle pour la tranche à taux 0%" do
    @user.update!(revenu_demandeur: 122_800)
    result = calculate(50_000)
    assert_equal 0.0, result[:taux_reduction]
    assert_equal 0.0, result[:reduction_solde]
  end
end
