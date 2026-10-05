require "test_helper"

# Tunnel d'onboarding : le type de bien régional et le profil demandeur sont
# demandés à la création du bien (région choisie).
class OnboardingRegionalFieldsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users

  setup do
    @user = users(:freemium_user)
    @user.update_column(:onboarding_completed_at, nil)
    sign_in @user
  end

  test "wallonie sans type de propriété ni profil : refusé" do
    assert_no_difference "Property.count" do
      post onboarding_create_proprietaire_bien_path(locale: :fr),
           params: { property: { rue: "Rue de Namur", numero: "1", code_postal: "5000", commune: "Namur", region: "wallonie" } }
    end
    assert_response :unprocessable_entity
  end

  test "wallonie avec type de propriété et profil : bien créé" do
    assert_difference "Property.count", 1 do
      post onboarding_create_proprietaire_bien_path(locale: :fr),
           params: { property: { rue: "Rue de Namur", numero: "1", code_postal: "5000", commune: "Namur", region: "wallonie",
                                 type_propriete_wallonie: "unique_proprietaire", profil_demandeur: "propriétaire_occupant_ou_futur_occupant" } }
    end
    bien = Property.order(:id).last
    assert_equal "unique_proprietaire", bien.type_propriete_wallonie
    assert_equal "propriétaire_occupant_ou_futur_occupant", bien.profil_demandeur
  end

  test "flandre : le type de bien flamand est enregistré" do
    post onboarding_create_proprietaire_bien_path(locale: :fr),
         params: { property: { rue: "Veldstraat", numero: "1", code_postal: "9000", commune: "Gent", region: "flandre",
                               type_bien_flandre: "maison", profil_demandeur: "proprietaire_occupant_ou_futur_occupant" } }
    assert_equal "maison", Property.order(:id).last.type_bien_flandre
  end
end
