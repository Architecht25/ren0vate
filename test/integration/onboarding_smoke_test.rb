require "test_helper"

# Smoke tests des tunnels d'onboarding.
# Pas de Selenium — tests HTTP via ActionDispatch::IntegrationTest.
# Objectif : vérifier que les flux ne crashent pas (non-régression).
class OnboardingSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users

  # ─── Helpers ──────────────────────────────────────────────────────────────

  def fresh_user(email:, profile: nil, professional_type: nil)
    user = User.create!(
      email: email,
      password: "password123",
      nom: "Test User",
      role: 0,
      user_profile: profile || 0
    )
    user.update_column(:professional_type, professional_type) if professional_type
    user
  end

  # ─── Profil sélection ─────────────────────────────────────────────────────

  test "page sélection profil accessible à un nouvel utilisateur" do
    user = fresh_user(email: "newuser_profil@example.com")
    sign_in user
    get onboarding_profile_selection_path(locale: :fr)
    assert_response :success
  end

  test "redirection vers dashboard si onboarding déjà fait" do
    user = users(:freemium_user)
    user.update_column(:onboarding_completed_at, 1.day.ago)
    sign_in user
    get onboarding_profile_selection_path(locale: :fr)
    assert_redirected_to dashboard_path(locale: :fr)
  end

  # ─── Tunnel Propriétaire ──────────────────────────────────────────────────

  test "tunnel propriétaire : sélection profil → bien → projet → préparation du projet" do
    user = fresh_user(email: "proprio_smoke@example.com")
    sign_in user

    # Étape 1 : sélectionner le profil "proprietaire"
    post onboarding_set_profile_path(locale: :fr), params: { profile: "proprietaire" }
    assert_redirected_to onboarding_proprietaire_bien_path(locale: :fr)

    # Étape 2 : créer le bien
    post onboarding_create_proprietaire_bien_path(locale: :fr), params: {
      property: { rue: "Rue Test", numero: "1", code_postal: "5000", commune: "Namur", region: "wallonie" }
    }
    assert_redirected_to onboarding_proprietaire_projet_path(locale: :fr)

    # Étape 3 : créer le projet — redirection directe vers l'onglet "préparation" du
    # projet créé (plutôt qu'un dashboard générique vide), voir
    # OnboardingController#create_proprietaire_projet. Comportement intentionnel,
    # pas une régression (cf. LAUNCH_CHECKLIST_OCT2026.md §2).
    post onboarding_create_proprietaire_projet_path(locale: :fr), params: {
      project: { nom: "Mon projet test", project_type: "renovation" }
    }

    user.reload
    project = user.properties.first.projects.first
    assert_redirected_to project_path(project, locale: :fr, tab: :preparation)

    assert user.onboarding_done?, "L'onboarding doit être marqué terminé"
    assert_equal 1, user.properties.count
    assert_equal 1, user.properties.first.projects.count
  end

  # ─── Tunnel Architecte ────────────────────────────────────────────────────

  test "tunnel architecte : sélection profil → profil pro → dashboard" do
    user = fresh_user(email: "archi_smoke@example.com", profile: 1, professional_type: "architect")
    sign_in user

    # Étape 1 : sélectionner le profil "architecte"
    post onboarding_set_profile_path(locale: :fr), params: { profile: "architecte" }
    assert_redirected_to onboarding_architecte_profil_path(locale: :fr)

    # Étape 2 : compléter le profil pro
    post onboarding_create_architecte_profil_path(locale: :fr), params: {
      user: { nom_cabinet: "Cabinet Dupont", num_bce: "0123456789" }
    }
    assert_redirected_to dashboard_path(locale: :fr)

    user.reload
    assert user.onboarding_done?
  end

  # ─── Tunnel Entrepreneur ──────────────────────────────────────────────────

  test "tunnel entrepreneur : passer l'invitation → dashboard pro" do
    user = fresh_user(email: "entrepreneur_smoke@example.com", profile: 2, professional_type: "entrepreneur")
    sign_in user

    # Étape 1 : sélectionner le profil "entrepreneur"
    post onboarding_set_profile_path(locale: :fr), params: { profile: "entrepreneur" }
    assert_redirected_to onboarding_entrepreneur_invitation_path(locale: :fr)

    # Étape 2 : passer sans token
    post onboarding_create_entrepreneur_invitation_path(locale: :fr), params: { invitation_token: "" }
    assert_redirected_to member_projects_path(locale: :fr)

    user.reload
    assert user.onboarding_done?
  end

  # ─── Tunnel Intermédiaire ─────────────────────────────────────────────────

  test "tunnel intermédiaire : structure → dashboard" do
    user = fresh_user(email: "intermediaire_smoke@example.com", profile: 3, professional_type: "intermediary")
    sign_in user

    # Étape 1 : sélectionner le profil "intermediaire"
    post onboarding_set_profile_path(locale: :fr), params: { profile: "intermediaire" }
    assert_redirected_to onboarding_intermediaire_structure_path(locale: :fr)

    # Étape 2 : compléter la structure
    post onboarding_create_intermediaire_structure_path(locale: :fr), params: {
      user: { nom_cabinet: "Structure Test", num_bce: "9876543210" }
    }
    assert_redirected_to dashboard_path(locale: :fr)

    user.reload
    assert user.onboarding_done?
  end

  # ─── Reconnexion après onboarding ─────────────────────────────────────────

  test "utilisateur avec onboarding terminé accède directement au dashboard" do
    user = users(:freemium_user)
    user.update_column(:onboarding_completed_at, 1.day.ago)
    sign_in user
    get dashboard_path(locale: :fr)
    assert_response :success
  end

  test "accès refusé si non connecté" do
    get onboarding_profile_selection_path(locale: :fr)
    assert_response :redirect
    assert_redirected_to new_user_session_path(locale: :fr)
  end
end
