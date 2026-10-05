require "test_helper"

# Avertissement affiché sur les pages de simulation quand le socle minimal
# d'un bien (profil demandeur, PEB, AER, chantier) n'est pas complet.
class SimulationPrerequisWarningTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users

  setup do
    @user = users(:freemium_user)
    @user.update_column(:onboarding_completed_at, 1.day.ago)
    sign_in @user

    @property = @user.properties.create!(
      titre: "Bien test",
      rue: "Rue de Namur", numero: "1", code_postal: "5000", commune: "Namur",
      region: "wallonie", skip_onboarding_validation: true
    )
  end

  test "bien sans socle complet : le bandeau liste les manquants" do
    manquants = @property.informations_de_base_manquantes

    assert_includes manquants, "Bien : profil demandeur"
    assert_includes manquants, "Bien : label PEB avant travaux"
    assert_includes manquants, "Profil : revenu du demandeur"
    assert_includes manquants, "Documents : avertissement extrait de rôle (AER)"
    assert_includes manquants, "Chantier : aucun chantier rattaché à ce bien"

    get new_simulation_path(locale: :fr)
    assert_response :success
    assert_select "div.alert-warning", text: /Complétez d'abord les informations de base/
  end

  test "bien avec socle complet : aucun manquant, pas de bandeau" do
    @user.update!(revenu_demandeur: 40_000)
    @property.update!(profil_demandeur: "Particulier", type_propriete_wallonie: "maison")
    PebDonnee.create!(property: @property, user: @user, phase: "avant_travaux", label_peb: "F", statut: "termine")
    @property.documents.create!(user: @user, type_document: "aer", status: "approved", file_url: "https://example.com/aer.pdf")
    Project.create!(user: @user, property: @property, nom: "Projet test", statut: "en_cours")

    assert_empty @property.reload.informations_de_base_manquantes

    get new_simulation_path(locale: :fr)
    assert_response :success
    # Le compte de test possède aussi un bien de fixture incomplet : on vérifie
    # seulement que le bien complet n'apparaît pas dans le bandeau.
    assert_select "div.alert-warning strong", text: "Bien test", count: 0
  end

  test "bonus PEB flamand : le label avant travaux E/F est bien lu" do
    flandre = @user.properties.create!(
      titre: "Bien Flandre", rue: "Veldstraat", numero: "1", code_postal: "9000", commune: "Gent",
      region: "flandre", skip_onboarding_validation: true
    )
    PebDonnee.create!(property: flandre, user: @user, phase: "avant_travaux", label_peb: "E", statut: "termine")
    service = Regions::Flandre::FlandreEligibilityService.new({ property_id: flandre.id }, user: @user)

    assert_equal "E", flandre.peb_label_avant_travaux
    assert service.send(:certificat_peb_e_f?, flandre)
  end
end
