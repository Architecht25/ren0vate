require "test_helper"

class PretReductionEligibilityServiceTest < ActiveSupport::TestCase
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
    Regions::Wallonie::PretReduction::EligibilityService.new(params, user: user)
  end

  def create_peb(label)
    PebDonnee.create!(
      user: @user,
      property: @property,
      region: "wallonie",
      phase: "avant_travaux",
      label_peb: label
    )
  end

  test "éligible avec label PEB F" do
    create_peb("F")
    result = service.check_eligibility
    assert result[:eligible], result[:message]
  end

  test "éligible avec label PEB G" do
    create_peb("G")
    result = service.check_eligibility
    assert result[:eligible], result[:message]
  end

  test "inéligible avec label PEB D (plus aucune aide pour D ou mieux)" do
    create_peb("D")
    result = service.check_eligibility
    assert_not result[:eligible]
    assert_match /PEB/, result[:message]
  end

  test "inéligible sans PEB renseigné" do
    result = service.check_eligibility
    assert_not result[:eligible]
    assert_match /PEB/, result[:message]
  end

  test "inéligible avec label PEB C (trop performant pour ce régime)" do
    create_peb("C")
    result = service.check_eligibility
    assert_not result[:eligible]
    assert_match /PEB/, result[:message]
  end

  test "utilise le PEB avant_travaux le plus récent" do
    create_peb("C")
    travel_to 1.day.from_now do
      create_peb("F")
    end
    result = service.check_eligibility
    assert result[:eligible], result[:message]
  end

  test "inéligible si bien pas situé en Wallonie" do
    @property.update!(region: "flandre", code_postal: "9000")
    create_peb("F")
    result = service.check_eligibility
    assert_not result[:eligible]
    assert_match /Wallonie/, result[:message]
  end

  test "inéligible sans utilisateur connecté" do
    result = service(user: nil).check_eligibility
    assert_not result[:eligible]
    assert_match /non connecté/i, result[:message]
  end

  test "inéligible si résidence secondaire (pas investissement, pas syndic/bailleur social)" do
    @property.update!(occupation: "residence_secondaire", profil_demandeur: "propriétaire_occupant_ou_futur_occupant")
    create_peb("F")
    result = service.check_eligibility
    assert_not result[:eligible]
    assert_match /résidence principale/i, result[:message]
  end

  test "éligible pour un propriétaire-bailleur (Rénoprêt) malgré l'absence de résidence principale" do
    @property.update!(occupation: "investissement")
    create_peb("F")
    result = service.check_eligibility
    assert result[:eligible], result[:message]
  end

  test "éligible pour un syndic de copropriété malgré l'absence de résidence principale" do
    @property.update!(occupation: "residence_secondaire", profil_demandeur: "syndic_copropriété")
    create_peb("F")
    result = service.check_eligibility
    assert result[:eligible], result[:message]
  end

  test "éligible pour un bailleur social malgré l'absence de résidence principale" do
    @property.update!(occupation: "residence_secondaire", profil_demandeur: "bailleur_social")
    create_peb("F")
    result = service.check_eligibility
    assert result[:eligible], result[:message]
  end
end
