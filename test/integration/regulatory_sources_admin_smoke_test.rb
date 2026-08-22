require "test_helper"

# Smoke tests de l'écran admin de veille réglementaire.
class RegulatorySourcesAdminSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users

  FakeResponse = Struct.new(:success, :body) do
    def success? = success
  end

  setup do
    # Email de bypass 2FA admin (ApplicationController::ADMIN_2FA_BYPASS_EMAIL) —
    # évite de simuler tout le flux /admin/2fa pour un simple smoke test.
    admin_email = ENV.fetch("ADMIN_2FA_BYPASS_EMAIL", "robin@primes-services.be")
    @admin = User.create!(email: admin_email, password: "password123", nom: "Admin", role: :admin)
    @user  = users(:freemium_user)
    @source = RegulatorySource.create!(url: "https://example.be/primes", label: "Source test", region: "wallonie")
  end

  test "page accessible à un admin" do
    sign_in @admin
    get admin_regulatory_sources_path(locale: :fr)
    assert_response :success
    assert_match @source.label, @response.body
  end

  test "refusée à un utilisateur non admin" do
    sign_in @user
    get admin_regulatory_sources_path(locale: :fr)
    assert_redirected_to root_path(locale: :fr)
  end

  test "check_now déclenche une vérification et redirige avec un message" do
    sign_in @admin
    original_get = HTTParty.method(:get)

    begin
      HTTParty.define_singleton_method(:get) { |*| FakeResponse.new(true, "<html><body>ok</body></html>") }
      post check_now_admin_regulatory_sources_path(locale: :fr)
      assert_redirected_to admin_regulatory_sources_path(locale: :fr)
    ensure
      HTTParty.define_singleton_method(:get, original_get)
    end

    assert @source.reload.last_checked_at.present?
  end
end
