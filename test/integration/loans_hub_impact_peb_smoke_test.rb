require "test_helper"

# Smoke tests du simulateur "Impact PEB sur mon taux" (loans_hub#impact_peb).
# Couvre l'état vide (pas de PEB scanné), le cas éligible, le cas rénovation
# (avant/après) et le cas donnée insuffisante — cf. Subsidies::PebRateImpactEstimatorService.
class LoansHubImpactPebSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(
      email: "proprietaire.peb@example.com", password: "password123",
      nom: "Lambert", role: 0, onboarding_completed_at: 1.day.ago
    )
    @property = @user.properties.create!(
      titre: "Maison Lambert", rue: "Rue de l'Isolation", numero: "7",
      code_postal: "4000", commune: "Liège", region: "wallonie",
      skip_onboarding_validation: true
    )
    sign_in @user
  end

  test "état vide : aucun certificat PEB scanné" do
    get loans_hub_impact_peb_path(property_id: @property.id, locale: :fr)
    assert_response :success
    assert_match "Scanner mon certificat PEB", @response.body
  end

  test "cas éligible : score PEB avant travaux sous le seuil" do
    @property.peb_donnees.create!(
      user: @user, phase: "avant_travaux", region: "wallonie",
      label_peb: "A", score_ep: 90
    )

    get loans_hub_impact_peb_path(property_id: @property.id, locale: :fr)
    assert_response :success
    assert_match "BNP Paribas Fortis", @response.body
    assert_match "Belfius", @response.body
    assert_match "CBC (KBC Wallonie)", @response.body
    assert_match "Éligible", @response.body
  end

  test "cas rénovation : réduction du score d'au moins 30% entre avant et après travaux" do
    @property.peb_donnees.create!(
      user: @user, phase: "avant_travaux", region: "wallonie",
      label_peb: "F", score_ep: 400
    )
    @property.peb_donnees.create!(
      user: @user, phase: "apres_travaux", region: "wallonie",
      label_peb: "C", score_ep: 200
    )

    get loans_hub_impact_peb_path(property_id: @property.id, locale: :fr)
    assert_response :success

    impacts = Subsidies::PebRateImpactEstimatorService.new(
      peb_avant: @property.peb_donnees.avant_travaux.first,
      peb_apres: @property.peb_donnees.apres_travaux.first
    ).call
    belfius = impacts.find { |i| i[:banque] == "Belfius" }
    assert_equal true, belfius[:eligible]
  end

  test "cas donnée insuffisante : certificat scanné sans score ni label exploitable" do
    @property.peb_donnees.create!(
      user: @user, phase: "avant_travaux", region: "wallonie"
    )

    get loans_hub_impact_peb_path(property_id: @property.id, locale: :fr)
    assert_response :success
    assert_match "Non déterminé", @response.body
    assert_match "Donnée insuffisante", @response.body
  end

  # Vues touchées par l'ajout de la 5e carte / du lien dashboard — non-régression ERB.
  test "index loans_hub affiche la carte impact PEB" do
    get loans_hub_path(property_id: @property.id, locale: :fr)
    assert_response :success
    assert_match "Impact PEB sur mon taux", @response.body
  end

  test "dashboard property affiche le lien impact PEB quand un certificat avant travaux existe" do
    @property.peb_donnees.create!(user: @user, phase: "avant_travaux", region: "wallonie", label_peb: "D", score_ep: 220)

    get dashboard_property_path(@property, locale: :fr)
    assert_response :success
    assert_match "Impact sur mon taux de prêt", @response.body
  end
end
