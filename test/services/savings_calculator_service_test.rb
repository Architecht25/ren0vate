require 'test_helper'

class SavingsCalculatorServiceTest < ActiveSupport::TestCase
  def setup
    @simulation_total = 20000.0
    @region_flandre = 'flandre'
    @region_wallonie = 'wallonie'
    @region_bruxelles = 'bruxelles'
  end

  test "calculates chasseur cost correctly" do
    service = SavingsCalculatorService.new(@simulation_total, @region_flandre)
    savings = service.calculate_savings

    # 20000 * 0.125 * 1.21 = 3025
    assert_equal 3025.0, savings[:chasseur_cost]
  end

  test "calculates saas cost for flandre correctly" do
    service = SavingsCalculatorService.new(@simulation_total, @region_flandre)
    savings = service.calculate_savings

    # 29.99 * 29 = 869.71
    expected_cost = (29.99 * 29).round(2)
    assert_equal expected_cost, savings[:saas_cost]
  end

  test "calculates saas cost for wallonie correctly" do
    service = SavingsCalculatorService.new(@simulation_total, @region_wallonie)
    savings = service.calculate_savings

    # 29.99 * 24 = 719.76
    expected_cost = (29.99 * 24).round(2)
    assert_equal expected_cost, savings[:saas_cost]
  end

  test "calculates saas cost for bruxelles correctly" do
    service = SavingsCalculatorService.new(@simulation_total, @region_bruxelles)
    savings = service.calculate_savings

    # 34.99 * 18 = 629.82
    expected_cost = (34.99 * 18).round(2)
    assert_equal expected_cost, savings[:saas_cost]
  end

  test "calculates savings amount correctly for flandre" do
    service = SavingsCalculatorService.new(@simulation_total, @region_flandre)
    savings = service.calculate_savings

    chasseur_cost = 3025.0
    saas_cost = (29.99 * 29).round(2)
    expected_savings = (chasseur_cost - saas_cost).round(2)

    assert_equal expected_savings, savings[:savings_amount]
    assert savings[:savings_amount] > 2000, "Les économies devraient être significatives"
  end

  test "calculates savings percentage correctly" do
    service = SavingsCalculatorService.new(@simulation_total, @region_flandre)
    savings = service.calculate_savings

    expected_percentage = ((savings[:savings_amount] / savings[:chasseur_cost]) * 100).round(1)
    assert_equal expected_percentage, savings[:savings_percentage]
    assert savings[:savings_percentage] > 70, "Le pourcentage d'économie devrait être élevé"
  end

  test "returns nil for zero simulation total" do
    service = SavingsCalculatorService.new(0, @region_flandre)
    assert_nil service.calculate_savings
  end

  test "returns nil for blank region" do
    service = SavingsCalculatorService.new(@simulation_total, nil)
    assert_nil service.calculate_savings
  end

  test "significant_savings? returns true for large savings" do
    service = SavingsCalculatorService.new(@simulation_total, @region_flandre)
    assert service.significant_savings?
  end

  test "significant_savings? returns false for small savings" do
    service = SavingsCalculatorService.new(1000, @region_flandre)
    refute service.significant_savings?
  end

  test "includes subscription details" do
    service = SavingsCalculatorService.new(@simulation_total, @region_flandre)
    savings = service.calculate_savings

    assert_equal 29.99, savings[:subscription_details][:monthly_price]
    assert_equal 29, savings[:subscription_details][:duration_months]
    assert_equal 'flandre', savings[:subscription_details][:region]
  end

  test "handles unknown region gracefully" do
    service = SavingsCalculatorService.new(@simulation_total, 'unknown_region')
    assert_nil service.calculate_savings
  end

  test "example calculation matches specification" do
    # Test avec l'exemple donné : 20.000€ de simulation en Flandre
    service = SavingsCalculatorService.new(20000, 'flandre')
    savings = service.calculate_savings

    # Chasseur : 20.000 * 12.5% + TVA = 3.025€
    assert_equal 3025.0, savings[:chasseur_cost]

    # SaaS : 29.99€ * 29 mois = 869.71€
    assert_equal 869.71, savings[:saas_cost]

    # Économie : 3.025 - 869.71 = 2.155,29€
    assert_equal 2155.29, savings[:savings_amount]

    # Plus de 70% d'économie
    assert savings[:savings_percentage] > 70
  end
end
