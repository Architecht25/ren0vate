require "test_helper"

# Smoke tests des pages de simulation.
# Objectif : vérifier que les pages s'affichent sans 500 (non-régression).
class SimulationSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users

  setup do
    @user = users(:freemium_user)
    @user.update_column(:onboarding_completed_at, 1.day.ago)
    sign_in @user

    @property_wallonie = @user.properties.create!(
      titre: "Bien Wallonie",
      rue: "Rue de Namur", numero: "1", code_postal: "5000", commune: "Namur",
      region: "wallonie", skip_onboarding_validation: true
    )
    @project_wallonie = Project.create!(
      user: @user, property: @property_wallonie, nom: "Projet Wallonie", statut: "en_cours"
    )

    @property_flandre = @user.properties.create!(
      titre: "Bien Flandre",
      rue: "Veldstraat", numero: "1", code_postal: "9000", commune: "Gent",
      region: "flandre", skip_onboarding_validation: true
    )
    @project_flandre = Project.create!(
      user: @user, property: @property_flandre, nom: "Projet Flandre", statut: "en_cours"
    )

    @property_bruxelles = @user.properties.create!(
      titre: "Bien Bruxelles",
      rue: "Avenue Louise", numero: "1", code_postal: "1050", commune: "Ixelles",
      region: "bruxelles", skip_onboarding_validation: true
    )
    @project_bruxelles = Project.create!(
      user: @user, property: @property_bruxelles, nom: "Projet Bruxelles", statut: "en_cours"
    )
  end

  # ─── Index ────────────────────────────────────────────────────────────────

  test "liste des simulations accessible" do
    get simulations_path(locale: :fr)
    assert_response :success
  end

  # ─── Création ─────────────────────────────────────────────────────────────

  test "création simulation Wallonie" do
    assert_difference "Simulation.count", 1 do
      post simulations_path(locale: :fr), params: {
        simulation: {
          titre: "Simulation Wallonie test",
          property_id: @property_wallonie.id,
          project_id: @project_wallonie.id,
          region: "wallonie"
        }
      }
    end
    assert_response :redirect
    follow_redirect!
    assert_response :success
  end

  test "création simulation Flandre" do
    assert_difference "Simulation.count", 1 do
      post simulations_path(locale: :fr), params: {
        simulation: {
          titre: "Simulation Flandre test",
          property_id: @property_flandre.id,
          project_id: @project_flandre.id,
          region: "flandre"
        }
      }
    end
    assert_response :redirect
    follow_redirect!
    assert_response :success
  end

  test "création simulation Bruxelles" do
    assert_difference "Simulation.count", 1 do
      post simulations_path(locale: :fr), params: {
        simulation: {
          titre: "Simulation Bruxelles test",
          property_id: @property_bruxelles.id,
          project_id: @project_bruxelles.id,
          region: "bruxelles"
        }
      }
    end
    assert_response :redirect
    follow_redirect!
    assert_response :success
  end

  # ─── Accès refusé ─────────────────────────────────────────────────────────

  test "accès refusé à une simulation d'un autre utilisateur" do
    other_user = User.create!(email: "other_sim@example.com", password: "password123", nom: "Other", role: 0)
    other_prop = other_user.properties.create!(
      titre: "Bien Other", rue: "Rue A", numero: "1", code_postal: "5000", commune: "Namur",
      region: "wallonie", skip_onboarding_validation: true
    )
    other_proj = Project.create!(user: other_user, property: other_prop, nom: "Proj Other", statut: "ok")
    other_sim = Simulation.create!(user: other_user, property: other_prop, project: other_proj, region: "wallonie", titre: "Sim Other")

    get simulation_path(other_sim, locale: :fr)
    assert_response :redirect
  end

  # ─── Non connecté ─────────────────────────────────────────────────────────

  test "accès refusé si non connecté" do
    sign_out @user
    get simulations_path(locale: :fr)
    assert_response :redirect
  end
end
