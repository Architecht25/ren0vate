require "test_helper"

# Smoke tests du suivi de dossier de prêt bonifié wallon (PretWallonieDossier).
class PretWallonieDossiersSmokeTest < ActionDispatch::IntegrationTest
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
    @simulation = Simulation.create!(
      user: @user, property: @property, project: @project, titre: "Simulation test",
      region: "wallonie", regime: "reduction_pret", eligible: true,
      parameters: {
        montant_projet_retenu: 20_000, plafond_emprunt: 75_000,
        taux_reduction: 0.50, taux_interet: "zero", ecomateriaux: false
      }.to_json
    )
  end

  test "démarrer le suivi crée un dossier à partir de la dernière simulation éligible" do
    assert_difference "PretWallonieDossier.count", 1 do
      post project_pret_wallonie_dossier_path(@project, locale: :fr)
    end
    assert_redirected_to project_pret_wallonie_dossier_path(@project, locale: :fr)

    dossier = @project.pret_wallonie_dossier
    assert_equal "preparation", dossier.statut
    assert_equal 20_000, dossier.montant_emprunte.to_i
  end

  test "refuse de démarrer le suivi sans simulation éligible" do
    @simulation.update!(eligible: false)
    assert_no_difference "PretWallonieDossier.count" do
      post project_pret_wallonie_dossier_path(@project, locale: :fr)
    end
    assert_redirected_to project_path(@project, locale: :fr)
  end

  test "page de suivi accessible une fois le dossier créé" do
    post project_pret_wallonie_dossier_path(@project, locale: :fr)
    get project_pret_wallonie_dossier_path(@project, locale: :fr)
    assert_response :success
  end

  test "mise à jour du statut et des dates" do
    post project_pret_wallonie_dossier_path(@project, locale: :fr)

    patch project_pret_wallonie_dossier_path(@project, locale: :fr), params: {
      pret_wallonie_dossier: {
        statut: "dossier_depose",
        date_depot: Date.current.to_s
      }
    }
    assert_redirected_to project_pret_wallonie_dossier_path(@project, locale: :fr)

    dossier = @project.pret_wallonie_dossier.reload
    assert_equal "dossier_depose", dossier.statut
    assert_equal Date.current, dossier.date_depot
  end

  test "la carte primes_hub affiche la simulation éligible sans dossier" do
    get primes_hub_path(locale: :fr)
    assert_response :success
    assert_match "Wallonie — Prêt bonifié", @response.body
  end
end
