require "test_helper"

class PretReductionTrancheServiceTest < ActiveSupport::TestCase
  fixtures :users

  setup do
    @user = users(:freemium_user)
    @user.update!(situation_familiale: "celibataire", nombre_enfants: 0)
  end

  def tranche_service
    Regions::Wallonie::PretReduction::TrancheService.new(@user)
  end

  test "taux 50% pour revenu <= 28 900€" do
    @user.update!(revenu_demandeur: 28_900)
    assert_equal 0.50, tranche_service.taux_reduction
  end

  test "taux 40% juste au-dessus de 28 900€" do
    @user.update!(revenu_demandeur: 28_901)
    assert_equal 0.40, tranche_service.taux_reduction
  end

  test "taux 40% pour revenu <= 41 100€" do
    @user.update!(revenu_demandeur: 41_100)
    assert_equal 0.40, tranche_service.taux_reduction
  end

  test "taux 15% pour revenu <= 67 100€" do
    @user.update!(revenu_demandeur: 67_100)
    assert_equal 0.15, tranche_service.taux_reduction
  end

  test "taux 0% pour revenu <= 122 800€" do
    @user.update!(revenu_demandeur: 122_800)
    assert_equal 0.0, tranche_service.taux_reduction
  end

  test "aucune tranche au-delà de 122 800€" do
    @user.update!(revenu_demandeur: 122_801)
    assert_not tranche_service.eligible_income?
    assert_equal 0.0, tranche_service.taux_reduction
    assert_nil tranche_service.taux_interet
  end

  test "taux d'intérêt à 0% pour les trois tranches jusqu'à 67 100€" do
    @user.update!(revenu_demandeur: 28_900)
    assert_equal :zero, tranche_service.taux_interet
    assert_equal "0%", tranche_service.taux_interet_label

    @user.update!(revenu_demandeur: 67_100)
    assert_equal :zero, tranche_service.taux_interet
  end

  test "taux d'intérêt réduit (non nul) entre 67 100,01€ et 122 800€" do
    @user.update!(revenu_demandeur: 122_800)
    assert_equal :reduit, tranche_service.taux_interet
    assert_equal "Taux réduit", tranche_service.taux_interet_label
  end
end
