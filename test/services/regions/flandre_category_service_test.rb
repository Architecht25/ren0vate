require "test_helper"

class FlandreCategoryServiceTest < ActiveSupport::TestCase
  fixtures :users

  setup do
    @user = users(:freemium_user)
    @user.update!(revenu_demandeur: 30_000, situation_familiale: "seul", nombre_enfants: 0)
    @property = @user.properties.create!(
      titre: "Bureau Gand",
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
      type_propriete_flandre: "commercial",
      skip_onboarding_validation: true
    )
    @project = Project.create!(
      user: @user,
      property: @property,
      nom: "Rénovation bureau",
      statut: "en_cours"
    )
    @params = { property_id: @property.id, project_id: @project.id }
  end

  def service(user: @user, params: @params)
    Regions::Flandre::FlandreCategoryService.new(params, user: user)
  end

  test "bâtiment non résidentiel exclu totalement depuis la réforme du 01/03/2026" do
    result = service.determine_category

    assert_equal false, result[:eligible]
    assert_nil result[:category]
    assert_match(/non résidentiel/i, result[:error])
    assert_match(/01\/03\/2026/, result[:error])
  end

  test "logement résidentiel classique reste éligible avec une catégorie calculée" do
    @property.update!(type_propriete_flandre: "woning", habitation_percentage: 100)

    result = service.determine_category

    assert result[:eligible]
    assert_includes %w[1 2 3 4], result[:category]
  end
end
