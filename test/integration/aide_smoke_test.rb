require "test_helper"

class AideSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users

  test "GET /aide renders successfully for a guest" do
    get "/fr/aide"
    assert_response :success
  end

  test "GET /aide renders successfully for a signed-in user" do
    user = users(:freemium_user)
    user.update_column(:onboarding_completed_at, 1.day.ago)
    sign_in user

    get "/fr/aide"
    assert_response :success
  end

  test "GET /aide?profil=architecte activates the architecte tab" do
    get "/fr/aide", params: { profil: "architecte" }
    assert_response :success
    assert_select "button#tab-architecte-btn.active"
    assert_select "div#tab-architecte.show.active"
  end

  test "GET /aide with an unknown profil falls back to proprietaire" do
    get "/fr/aide", params: { profil: "not-a-real-profile" }
    assert_response :success
    assert_select "button#tab-proprietaire-btn.active"
  end
end
