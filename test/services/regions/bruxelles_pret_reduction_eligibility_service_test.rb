require "test_helper"

class BruxellesPretReductionEligibilityServiceTest < ActiveSupport::TestCase
  fixtures :users

  setup do
    @user = users(:freemium_user)
    @user.update!(situation_familiale: "celibataire", nombre_enfants: 0, revenu_demandeur: 28_900)
    @property = @user.properties.create!(
      titre: "Maison Ixelles",
      rue: "Avenue Louise",
      numero: "1",
      code_postal: "1050",
      commune: "Ixelles",
      region: "bruxelles",
      annee_construction: 1950,
      habitation_percentage: 100,
      occupation: "residence_principale",
      type_propriete_wallonie: "proprietaire",
      skip_onboarding_validation: true
    )
    @project = Project.create!(user: @user, property: @property, nom: "Rénovation Ixelles", statut: "en_cours")
    @params = { property_id: @property.id, project_id: @project.id }
  end

  def service(user: @user)
    Regions::Bruxelles::PretReduction::EligibilityService.new(@params, user: user)
  end

  def create_peb(label)
    PebDonnee.create!(user: @user, property: @property, region: "bruxelles", phase: "avant_travaux", label_peb: label)
  end

  test "éligible pour une passoire énergétique (PEB F)" do
    create_peb("F")
    result = service.check_eligibility
    assert result[:eligible], result[:message]
  end

  test "inéligible avec un label PEB D" do
    create_peb("D")
    result = service.check_eligibility
    assert_not result[:eligible]
    assert_match /PEB/, result[:message]
  end

  test "inéligible hors Bruxelles" do
    create_peb("F")
    @property.update_columns(region: "wallonie", code_postal: "5000")
    result = service.check_eligibility
    assert_not result[:eligible]
    assert_match /Bruxelles/, result[:message]
  end

  test "inéligible au-dessus du plafond de revenus (122.800 €)" do
    create_peb("F")
    @user.update!(revenu_demandeur: 130_000)
    result = service.check_eligibility
    assert_not result[:eligible]
    assert_match /Revenus/, result[:message]
  end

  test "inéligible sans utilisateur connecté" do
    result = service(user: nil).check_eligibility
    assert_not result[:eligible]
  end
end
