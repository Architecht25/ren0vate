require "test_helper"

# Couvre le bug signalé par Robin le 29/10/2026 : un utilisateur sur le plan
# Starter (freemium) pouvait uploader/consulter factures, devis et documents
# alors que l'offre Starter exclut explicitement le "dossier documentaire"
# (cf. site/pricing_controller.rb). can_access_feature?(:dossier_documentaire)
# existait déjà dans user.rb mais n'était jamais branché à aucun controller —
# voir check_dossier_documentaire_access! dans application_controller.rb.
class DossierDocumentaireAccessSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users, :properties, :projects, :subscriptions

  test "un utilisateur freemium est redirigé hors des documents d'un projet" do
    sign_in users(:freemium_user)
    get project_documents_path(projects(:one), locale: :fr)
    assert_redirected_to pricing_select_path(locale: :fr)
  end

  test "un utilisateur freemium est redirigé hors des factures d'un projet" do
    sign_in users(:freemium_user)
    get project_factures_path(projects(:one), locale: :fr)
    assert_redirected_to pricing_select_path(locale: :fr)
  end

  test "un utilisateur freemium est redirigé hors du dossier documentaire V2" do
    sign_in users(:freemium_user)
    get project_project_documents_path(projects(:one), locale: :fr)
    assert_redirected_to pricing_select_path(locale: :fr)
  end

  test "un utilisateur freemium est redirigé hors des devis structurés V2" do
    sign_in users(:freemium_user)
    get project_project_quotes_path(projects(:one), locale: :fr)
    assert_redirected_to pricing_select_path(locale: :fr)
  end

  test "un utilisateur individual accède normalement aux documents d'un projet" do
    sign_in users(:individual_user)
    get project_documents_path(projects(:two), locale: :fr)
    assert_response :success
  end

  test "l'estimateur de devis (Quote, feature freemium) reste accessible en freemium" do
    sign_in users(:freemium_user)
    get property_quotes_path(properties(:one), locale: :fr)
    assert_response :success
  end
end
