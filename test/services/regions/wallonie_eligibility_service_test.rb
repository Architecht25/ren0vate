require "test_helper"

class WallonieEligibilityServiceTest < ActiveSupport::TestCase
  fixtures :users

  setup do
    @user = users(:freemium_user)
    @property = @user.properties.create!(
      titre: "Maison Namur",
      rue: "Rue de Namur",
      numero: "1",
      code_postal: "5000",
      commune: "Namur",
      region: "wallonie",
      annee_construction: 2000,
      habitation_percentage: 100,
      occupation: "residence_principale",
      type_propriete_wallonie: "proprietaire",
      skip_onboarding_validation: true
    )
    @project = Project.create!(
      user: @user,
      property: @property,
      nom: "Rénovation Namur",
      statut: "en_cours"
    )
    @params = { property_id: @property.id, project_id: @project.id }
  end

  def service(user: @user, params: @params)
    Regions::Wallonie::WallonieEligibilityService.new(params, user: user)
  end

  test "éligible quand tous les critères wallonie sont remplis" do
    result = service.check_eligibility
    assert result[:eligible], result[:message]
    assert_equal "Éligible aux primes Wallonie", result[:message]
  end

  test "inéligible sans utilisateur connecté" do
    result = service(user: nil).check_eligibility
    assert_not result[:eligible]
    assert_match /non connecté/i, result[:message]
  end

  test "inéligible si propriété introuvable" do
    result = service(params: { property_id: 0, project_id: @project.id }).check_eligibility
    assert_not result[:eligible]
    assert_equal "Propriété non trouvée", result[:message]
  end

  test "inéligible si projet introuvable" do
    result = service(params: { property_id: @property.id, project_id: 0 }).check_eligibility
    assert_not result[:eligible]
    assert_equal "Projet non trouvé", result[:message]
  end

  test "inéligible si bien pas situé en Wallonie" do
    @property.update!(region: "flandre", code_postal: "9000")
    result = service.check_eligibility
    assert_not result[:eligible]
    assert_match /Wallonie/, result[:message]
  end

  test "inéligible si logement construit il y a moins de 15 ans" do
    @property.update!(annee_construction: Date.current.year - 10)
    result = service.check_eligibility
    assert_not result[:eligible]
    assert_match /15 ans/, result[:message]
  end

  test "inéligible si résidence d'investissement" do
    @property.update!(occupation: "investissement")
    result = service.check_eligibility
    assert_not result[:eligible]
    assert_match /résidence principale/, result[:message]
  end
end
