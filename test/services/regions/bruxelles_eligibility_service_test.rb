require "test_helper"

class BruxellesEligibilityServiceTest < ActiveSupport::TestCase
  fixtures :users

  setup do
    @user = users(:freemium_user)
    @property = @user.properties.create!(
      titre: "Appartement Ixelles",
      rue: "Avenue Louise",
      numero: "1",
      code_postal: "1050",
      commune: "Ixelles",
      region: "bruxelles",
      type_bien_bruxelles: "appartement",
      skip_onboarding_validation: true
    )
    @project = Project.create!(
      user: @user,
      property: @property,
      nom: "Rénovation Bruxelles",
      statut: "en_cours"
    )
    @params = { property_id: @property.id, project_id: @project.id }
  end

  def service(user: @user, params: @params)
    Regions::Bruxelles::BruxellesEligibilityService.new(params, user: user)
  end

  test "éligible si bien situé à Bruxelles" do
    result = service.check_eligibility
    assert result[:eligible], result[:message]
    assert_match /Bruxelles/, result[:message]
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

  test "inéligible si bien hors Bruxelles" do
    @property.update!(region: "wallonie", code_postal: "5000")
    result = service.check_eligibility
    assert_not result[:eligible]
    assert_match /Bruxelles/, result[:message]
  end
end
