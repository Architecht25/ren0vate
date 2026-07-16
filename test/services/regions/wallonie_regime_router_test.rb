require "test_helper"

class WallonieRegimeRouterTest < ActiveSupport::TestCase
  test "primes_cash avant le 01/10/2026" do
    assert_equal "primes_cash", Regions::Wallonie::WallonieRegimeRouter.regime_for(date: Date.new(2026, 9, 30))
  end

  test "reduction_pret à partir du 01/10/2026" do
    assert_equal "reduction_pret", Regions::Wallonie::WallonieRegimeRouter.regime_for(date: Date.new(2026, 10, 1))
  end

  test "reduction_pret longtemps après la bascule" do
    assert_equal "reduction_pret", Regions::Wallonie::WallonieRegimeRouter.regime_for(date: Date.new(2027, 1, 1))
  end

  test "regime_for utilise Date.current par défaut" do
    travel_to Date.new(2026, 10, 1) do
      assert_equal "reduction_pret", Regions::Wallonie::WallonieRegimeRouter.regime_for
    end
  end
end
