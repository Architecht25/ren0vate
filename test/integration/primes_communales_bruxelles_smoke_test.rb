require "test_helper"

# Couvre la migration du 13/10/2026 : les primes communales bruxelloises
# n'ont plus qu'une seule source (public/data/primes_communales_bruxelles.json
# via Regions::PrimesCommunales::PrimesCommunalesBruxellesService), consommée
# à la fois par le Decision Hub (déjà en place) et par la carte "Primes
# Communales" de la page Simulation (auparavant un dictionnaire JS codé en
# dur, désynchronisé du JSON — voir mémoire project_primes_communales_bxl_unification).
class PrimesCommunalesBruxellesSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users, :properties

  test "l'API renvoie les vraies primes pour un code postal connu (Etterbeek)" do
    get "/fr/api/primes_communales_bruxelles", params: { code_postal: "1040" }
    assert_response :success

    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "Etterbeek", json["data"]["commune"]
    noms = json["data"]["primes"].map { |p| p["nom"] }
    assert_includes noms, "Prime compostière"
    assert_includes noms, "Subside transition écologique"
  end

  test "l'API renvoie une liste vide (pas une erreur) pour une commune sans prime connue" do
    get "/fr/api/primes_communales_bruxelles", params: { code_postal: "1083" } # Ganshoren
    assert_response :success

    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal [], json["data"]["primes"]
  end

  test "l'API rejette un code postal hors Bruxelles-Capitale" do
    get "/fr/api/primes_communales_bruxelles", params: { code_postal: "5000" } # Namur
    assert_response :bad_request
  end

  test "la page Simulation (Bruxelles) s'affiche et interroge l'API au lieu d'un dictionnaire codé en dur" do
    user = users(:freemium_user)
    user.update_column(:onboarding_completed_at, 1.day.ago)
    property = Property.new(user: user, region: "bruxelles", type_demandeur: "particulier",
      rue: "Rue Test", numero: "1", commune: "Etterbeek", code_postal: "1040", type_bien_bruxelles: "maison_unifamiliale")
    property.save!(validate: false)
    simulation = Simulation.new(user: user, property: property, region: "bruxelles", titre: "Simulation test")
    simulation.save!(validate: false)

    sign_in user
    get simulation_path(simulation, locale: :fr)
    assert_response :success
    assert_match "/fr/api/primes_communales_bruxelles", response.body
    assert_no_match "CP_TO_COMMUNE", response.body
  end
end
