require "test_helper"

# Le champ « client protégé » est porté par le bien (formulaire Flandre) :
# un client protégé doit recevoir la catégorie 4, quel que soit son revenu.
class FlandreClientProtegeTest < ActiveSupport::TestCase
  fixtures :users

  setup do
    @user = users(:freemium_user)
    @user.update!(revenu_demandeur: 90_000)
    @property = @user.properties.create!(
      titre: "Bien Flandre", rue: "Veldstraat", numero: "1", code_postal: "9000", commune: "Gent",
      region: "flandre", skip_onboarding_validation: true, client_protege_flandre: true
    )
  end

  test "catégorie : un bien marqué client protégé obtient la catégorie 4" do
    service = Regions::Flandre::FlandreCategoryService.new({ property_id: @property.id }, user: @user)
    result = service.send(:check_special_category_criteria, @property, nil)

    assert_equal "4", result[:category]
  end

  test "éligibilité : le contrôle client protégé lit le bien" do
    service = Regions::Flandre::FlandreEligibilityService.new({ property_id: @property.id }, user: @user)

    assert service.send(:est_client_protege?, @property)
    refute service.send(:est_client_protege?, @property.tap { |p| p.client_protege_flandre = false })
  end
end
