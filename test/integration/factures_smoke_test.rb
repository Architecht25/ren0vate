require "test_helper"

# Smoke test des pages factures (index/show/edit) fraîchement créées, et du
# formulaire de validation de devis par le client (pro_views#show) — les deux
# avaient des templates manquants / un helper de route cassé qui faisaient
# planter la page en production.
class FacturesSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users, :properties, :projects

  setup do
    @user = users(:freemium_user)
    @project = projects(:one)
    @document = Document.create!(
      project: @project,
      property: @project.property,
      user: @user,
      type_document: "facture",
      file_url: "https://example.com/facture.pdf"
    )
    @facture = Facture.create!(
      project: @project,
      document: @document,
      montant: 1500.0,
      type_facture: "facture",
      statut_paiement: "non_paye",
      type_intervenant: "entrepreneur"
    )
    sign_in @user
  end

  test "index des factures d'un projet s'affiche" do
    get project_factures_path(@project, locale: :fr)
    assert_response :success
  end

  test "détail d'une facture s'affiche" do
    get project_facture_path(@project, @facture, locale: :fr)
    assert_response :success
  end

  test "édition d'une facture s'affiche" do
    get edit_project_facture_path(@project, @facture, locale: :fr)
    assert_response :success
  end

  test "pro_views#show avec un devis entrepreneur à valider ne crashe pas" do
    devis_document = Document.create!(
      project: @project,
      property: @project.property,
      user: @user,
      type_document: "devis",
      file_url: "https://example.com/devis.pdf"
    )
    Facture.create!(
      project: @project,
      document: devis_document,
      montant: 5000.0,
      type_facture: "devis",
      type_intervenant: "entrepreneur",
      statut_paiement: "non_paye",
      validated_by_client_at: nil
    )

    get pro_view_project_path(@project, locale: :fr)
    assert_response :success
  end

  test "pro_views#show affiche un bouton retour pour un membre non-propriétaire" do
    architecte = User.create!(
      email: "architecte_test@example.com",
      password: "password123",
      nom: "Architecte Test",
      role: 0,
      user_profile: 0,
      professional_type: "architect"
    )
    ProjectMember.create!(project: @project, user: architecte, role: "architect", status: "active")
    sign_out @user
    sign_in architecte

    get pro_view_project_path(@project, locale: :fr)
    assert_response :success
    assert_select "a[href=?]", member_projects_path(locale: :fr), text: /Mes projets/
  end
end
