require "test_helper"

# Smoke test de /admin/dashboard — onglet Utilisateurs.
# Vérifie la sélection multiple par checkboxes (pour copier des emails) et le
# filtre Abonnement (bug : un utilisateur payant "individual" n'était pas
# remonté par le filtre).
class AdminDashboardSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users, :subscriptions

  # Admin::SystemInfoService#count_active_sessions interroge `current_sign_in_at`,
  # colonne absente (module Devise :trackable désactivé) : la requête échoue et
  # est avalée par un `rescue` interne au service (bug préexistant, hors scope
  # ici). Sans transaction englobante ça ne casse rien en prod (chaque requête
  # a sa propre transaction), mais ça empoisonnerait la transaction des fixtures.
  self.use_transactional_tests = false

  setup do
    @admin = User.create!(
      email: "robin@primes-services.be", # ADMIN_2FA_BYPASS_EMAIL, cf. application_controller.rb
      password: "password123",
      nom: "Admin Test",
      role: :admin,
      confirmed_at: 1.day.ago,
      onboarding_completed_at: 1.day.ago
    )
    sign_in @admin
  end

  teardown do
    @admin&.destroy
  end

  test "la page se charge sans erreur" do
    get admin_dashboard_path(locale: "fr")
    assert_response :success
  end

  test "chaque utilisateur a une checkbox de sélection avec son email" do
    get admin_dashboard_path(locale: "fr")
    assert_select "input.user-select-checkbox[data-email=?]", "individual@example.com"
    assert_select "input#selectAllUsers"
    assert_select "button#copySelectedEmailsBtn[disabled]"
  end

  test "le filtre abonnement expose le tier exact de l'utilisateur payant" do
    get admin_dashboard_path(locale: "fr")
    # L'utilisateur individual_user a un abonnement 'individual' actif (fixtures/subscriptions.yml)
    assert_select "tr[data-user-email=?][data-user-tier=?]", "individual@example.com", "individual"
    assert_select "select#tierFilter option[value=?]", "individual"
  end

  test "un utilisateur freemium expose le tier freemium" do
    get admin_dashboard_path(locale: "fr")
    assert_select "tr[data-user-email=?][data-user-tier=?]", "freemium@example.com", "freemium"
  end
end
