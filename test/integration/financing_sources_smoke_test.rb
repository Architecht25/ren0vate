require "test_helper"

# Smoke tests du plan de financement (FinancingSource) : création manuelle,
# refus de modification des lignes auto-synchronisées, autorisation d'accès.
class FinancingSourcesSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users

  setup do
    @user = users(:freemium_user)
    @user.update_column(:onboarding_completed_at, 1.day.ago)
    sign_in @user

    @property = @user.properties.create!(
      titre: "Bien Wallonie", rue: "Rue de Namur", numero: "1", code_postal: "5000", commune: "Namur",
      region: "wallonie", annee_construction: 2000, occupation: "residence_principale",
      type_propriete_wallonie: "proprietaire", skip_onboarding_validation: true
    )
    @project = Project.create!(user: @user, property: @property, nom: "Rénovation Namur", statut: "en_cours")
  end

  test "créer une source de financement manuelle" do
    assert_difference "FinancingSource.count", 1 do
      post project_financing_sources_path(@project, locale: :fr), params: {
        financing_source: { label: "Épargne", source_type: "fonds_propres", amount: 10_000 }
      }
    end
    assert_redirected_to project_path(@project, tab: "preparation", locale: :fr)

    source = @project.financing_sources.last
    assert_equal "fonds_propres", source.source_type
    assert_equal "simule", source.status
  end

  test "peut créer manuellement une prime déjà obtenue hors simulateur" do
    assert_difference "FinancingSource.count", 1 do
      post project_financing_sources_path(@project, locale: :fr), params: {
        financing_source: { label: "Prime communale", source_type: "prime", amount: 2_500, status: "obtenu" }
      }
    end

    source = @project.financing_sources.last
    assert_equal "prime", source.source_type
    assert_not source.auto_synced?
  end

  test "rejette un type de source invalide au profit de fonds_propres par défaut" do
    post project_financing_sources_path(@project, locale: :fr), params: {
      financing_source: { label: "Tentative", source_type: "inconnu", amount: 5_000 }
    }
    assert_equal "fonds_propres", @project.financing_sources.last.source_type
  end

  test "refuse de modifier une ligne auto-synchronisée" do
    simulation = Simulation.create!(
      user: @user, property: @property, project: @project, titre: "Simulation isolation",
      region: "wallonie", total_simule: 3_000
    )
    @project.sync_financing_sources!
    source = @project.financing_sources.find_by(source_type: "prime")

    patch project_financing_source_path(@project, source, locale: :fr), params: {
      financing_source: { amount: 99_999 }
    }
    assert_redirected_to project_path(@project, tab: "preparation", locale: :fr)
    assert_equal 3_000, source.reload.amount.to_i
  end

  test "refuse l'accès à un projet qui n'appartient pas à l'utilisateur" do
    autre_user = users(:individual_user)
    autre_property = autre_user.properties.create!(
      titre: "Autre bien", rue: "Rue X", numero: "1", code_postal: "1000", commune: "Bruxelles",
      region: "bruxelles", annee_construction: 2000, occupation: "residence_principale",
      skip_onboarding_validation: true
    )
    autre_project = Project.create!(user: autre_user, property: autre_property, nom: "Autre chantier", statut: "en_cours")

    post project_financing_sources_path(autre_project, locale: :fr), params: {
      financing_source: { label: "Intrusion", source_type: "fonds_propres", amount: 1_000 }
    }
    assert_redirected_to root_path(locale: :fr)
  end
end
