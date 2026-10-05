require "test_helper"

class BruxellesPretReductionCalculatorServiceTest < ActiveSupport::TestCase
  fixtures :users

  setup do
    @user = users(:freemium_user)
    @user.update!(situation_familiale: "celibataire", nombre_enfants: 0, revenu_demandeur: 28_900)
  end

  def calculate(montant_projet)
    Regions::Bruxelles::PretReduction::CalculatorService.new(@user, montant_projet: montant_projet).calculate
  end

  test "plafonne le montant retenu à 60.000 €" do
    result = calculate(100_000)
    assert_equal 60_000, result[:montant_projet_retenu]
    assert_equal 60_000, result[:plafond_emprunt]
  end

  test "réduction = montant retenu x taux de la tranche (barème wallon)" do
    # Revenu ajusté 28.900 € => tranche la plus favorable : 50 %
    result = calculate(100_000)
    assert_equal 0.50, result[:taux_reduction]
    assert_equal 30_000, result[:reduction_solde]
  end

  test "montant inférieur au plafond : pas de plafonnement" do
    result = calculate(20_000)
    assert_equal 20_000, result[:montant_projet_retenu]
    assert_equal 10_000, result[:reduction_solde]
  end

  test "taux d'intérêt du prêt affiché à 0 %" do
    assert_equal "0%", calculate(20_000)[:taux_interet_label]
  end

  test "revenus au-dessus de 122.800 € : réduction nulle" do
    @user.update!(revenu_demandeur: 130_000)
    assert_equal 0, calculate(50_000)[:reduction_solde]
  end
end
