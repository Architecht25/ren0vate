require "test_helper"

class FlandreEligibilityServiceTest < ActiveSupport::TestCase
  fixtures :users

  setup do
    @user = users(:freemium_user)
    @property = @user.properties.create!(
      titre: "Maison Gand",
      rue: "Veldstraat",
      numero: "1",
      code_postal: "9000",
      commune: "Gent",
      region: "flandre",
      annee_construction: 1990,
      habitation_percentage: 100,
      occupation: "residence_principale",
      type_bien_flandre: "woning",
      usage_flandre: "bewoning",
      skip_onboarding_validation: true
    )
    @project = Project.create!(
      user: @user,
      property: @property,
      nom: "Rénovation Flandre",
      statut: "en_cours"
    )
    @params = { property_id: @property.id, project_id: @project.id }
  end

  def service(user: @user, params: @params)
    Regions::Flandre::FlandreEligibilityService.new(params, user: user)
  end

  test "éligible quand tous les critères flandre sont remplis" do
    result = service.check_eligibility
    assert result[:eligible], result[:message]
    assert_equal "Éligible aux primes Flandre", result[:message]
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

  test "inéligible si bien construit après 2006" do
    @property.update!(annee_construction: 2010)
    result = service.check_eligibility
    assert_not result[:eligible]
    assert_match /2006/, result[:message]
  end

  test "inéligible si appartement en copropriété" do
    @property.update!(type_propriete_flandre: "appartement_copro")
    result = service.check_eligibility
    assert_not result[:eligible]
    assert_match /syndic/, result[:message]
  end

  test "inéligible si reconstruction après démolition" do
    @project.update!(reconstruction_demolition: true)
    result = service.check_eligibility
    assert_not result[:eligible]
    assert_match /TVA|démolition|reconstruction/i, result[:message]
  end

  test "inéligible si bien pas situé en Flandre" do
    @property.update!(region: "wallonie", code_postal: "5000")
    result = service.check_eligibility
    assert_not result[:eligible]
    assert_match /Flandre|flamande/i, result[:message]
  end
end
