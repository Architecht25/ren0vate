require "test_helper"

class UserTest < ActiveSupport::TestCase
  fixtures :users, :subscriptions
  # === subscription_tier ===

  test "subscription_tier returns freemium when no active subscription" do
    user = users(:freemium_user)
    # freemium_user has only a canceled subscription
    assert_equal "freemium", user.subscription_tier
  end

  test "subscription_tier returns tier of active subscription" do
    assert_equal "individual", users(:individual_user).subscription_tier
    assert_equal "portfolio",  users(:portfolio_user).subscription_tier
  end

  # === property_limit ===

  test "property_limit is 1 for freemium" do
    assert_equal 1, users(:freemium_user).property_limit
  end

  test "property_limit is 3 for individual" do
    assert_equal 3, users(:individual_user).property_limit
  end

  test "property_limit is 10 for portfolio" do
    assert_equal 10, users(:portfolio_user).property_limit
  end

  test "property_limit is unlimited for professional" do
    user = users(:freemium_user)
    user.subscriptions.create!(
      stripe_subscription_id: "sub_pro_test_#{SecureRandom.hex(4)}",
      tier: "professional",
      status: "active",
      current_period_start: 1.month.ago,
      current_period_end: 1.month.from_now
    )
    assert_equal Float::INFINITY, user.property_limit
  end

  # === project_limit ===

  test "project_limit is 1 for freemium" do
    assert_equal 1, users(:freemium_user).project_limit
  end

  test "project_limit is unlimited for individual and above" do
    assert_equal Float::INFINITY, users(:individual_user).project_limit
    assert_equal Float::INFINITY, users(:portfolio_user).project_limit
  end

  # === simulation_limit ===

  test "simulation_limit is 1 for freemium" do
    assert_equal 1, users(:freemium_user).simulation_limit
  end

  test "simulation_limit is unlimited for individual and above" do
    assert_equal Float::INFINITY, users(:individual_user).simulation_limit
    assert_equal Float::INFINITY, users(:portfolio_user).simulation_limit
  end

  # === ren0chat_monthly_limit ===

  test "ren0chat_monthly_limit is 5 for freemium" do
    assert_equal 5, users(:freemium_user).ren0chat_monthly_limit
  end

  test "ren0chat_monthly_limit is 50 for individual" do
    assert_equal 50, users(:individual_user).ren0chat_monthly_limit
  end

  test "ren0chat_monthly_limit is unlimited for professional_type present" do
    user = users(:individual_user)
    user.professional_type = "architect"
    assert_equal Float::INFINITY, user.ren0chat_monthly_limit
  end

  # === can_access_feature? ===

  test "freemium cannot access unlimited_properties" do
    assert_not users(:freemium_user).can_access_feature?(:unlimited_properties)
  end

  test "individual can access unlimited_properties" do
    assert users(:individual_user).can_access_feature?(:unlimited_properties)
  end

  test "freemium cannot access decision_hub" do
    assert_not users(:freemium_user).can_access_feature?(:decision_hub)
  end

  test "portfolio can access decision_hub" do
    assert users(:portfolio_user).can_access_feature?(:decision_hub)
  end
end
