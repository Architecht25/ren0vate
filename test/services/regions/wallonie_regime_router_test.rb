require "test_helper"

class WallonieRegimeRouterTest < ActiveSupport::TestCase
  test "primes_cash avant la bascule (17/07/2026)" do
    assert_equal "primes_cash", Regions::Wallonie::WallonieRegimeRouter.regime_for(date: Date.new(2026, 7, 16))
  end

  test "reduction_pret à partir du 17/07/2026" do
    assert_equal "reduction_pret", Regions::Wallonie::WallonieRegimeRouter.regime_for(date: Date.new(2026, 7, 17))
  end

  test "reduction_pret longtemps après la bascule" do
    assert_equal "reduction_pret", Regions::Wallonie::WallonieRegimeRouter.regime_for(date: Date.new(2027, 1, 1))
  end

  test "regime_for utilise Date.current par défaut" do
    travel_to Date.new(2026, 7, 17) do
      assert_equal "reduction_pret", Regions::Wallonie::WallonieRegimeRouter.regime_for
    end
  end
end
