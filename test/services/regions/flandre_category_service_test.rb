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

  # Ces deux tests utilisent portfolio_user (pas de bien en fixture) pour
  # isoler l'effet de la (non-)domiciliation du critère spécial "propriétaire
  # d'un autre bien" (freemium_user possède déjà un bien via fixture).
  def domiciliation_test_setup(occupation:, domicilie_flandre:)
    user = users(:portfolio_user)
    user.update!(revenu_demandeur: 30_000, situation_familiale: "seul", nombre_enfants: 0)
    property = user.properties.create!(
      titre: "Maison Gand",
      rue: "Veldstraat",
      numero: "1",
      code_postal: "9000",
      commune: "Gent",
      region: "flandre",
      annee_construction: 1990,
      habitation_percentage: 100,
      occupation: occupation,
      domicilie_flandre: domicilie_flandre,
      type_bien_flandre: "woning",
      usage_flandre: "bewoning",
      type_propriete_flandre: "woning",
      skip_onboarding_validation: true
    )
    project = Project.create!(user: user, property: property, nom: "Rénovation Flandre", statut: "en_cours")
    Regions::Flandre::FlandreCategoryService.new({ property_id: property.id, project_id: project.id }, user: user)
  end

  test "non domicilié (résidence secondaire) => catégorie 1 forcée (sera_domicilie? unifié)" do
    result = domiciliation_test_setup(occupation: "residence_secondaire", domicilie_flandre: nil).determine_category

    assert result[:eligible]
    assert_equal "1", result[:category]
    assert_match(/domicilié/i, result[:details])
  end

  test "domicilie_flandre = true (champ réel du formulaire) suffit à ne pas forcer la catégorie 1, même sans occupation" do
    result = domiciliation_test_setup(occupation: nil, domicilie_flandre: true).determine_category

    assert result[:eligible]
    # Revenu 30_000€, seul, sans charge => catégorie 3 (barème Flandre), pas de catégorie 1 forcée
    assert_equal "3", result[:category]
  end
end
