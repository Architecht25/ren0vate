require "test_helper"

# V2 — gestion des lots/phases après création du chantier (jusqu'ici créés
# seulement par défaut, sans moyen de les personnaliser — cahier des charges
# §4 : "personnalisables").
class LotsAndPhasesSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users, :properties, :projects

  setup do
    @owner = users(:freemium_user)
    @owner.update_column(:onboarding_completed_at, 1.day.ago)
    @project = projects(:one)
    sign_in @owner
  end

  test "index et new des lots s'affichent, create fonctionne" do
    get project_lots_path(@project, locale: :fr)
    assert_response :success

    get new_project_lot_path(@project, locale: :fr)
    assert_response :success

    assert_difference -> { Lot.count } => 1 do
      post project_lots_path(@project, locale: :fr), params: { lot: { name: "Électricité", key: "electricite" } }
    end
    assert_redirected_to project_lots_path(@project, locale: :fr)
  end

  test "modifier puis supprimer un lot" do
    lot = @project.lots.create!(name: "Toiture", key: "toiture", position: 0)

    get edit_lot_path(lot, locale: :fr)
    assert_response :success

    patch lot_path(lot, locale: :fr), params: { lot: { name: "Toiture — renommée" } }
    assert_equal "Toiture — renommée", lot.reload.name

    delete lot_path(lot, locale: :fr)
    assert_nil Lot.find_by(id: lot.id)
  end

  test "un utilisateur hors chantier ne peut pas gérer les lots" do
    outsider = User.create!(email: "outsider_lots@example.com", password: "password123", nom: "Outsider")
    lot = @project.lots.create!(name: "Toiture", key: "toiture", position: 0)
    sign_out @owner
    sign_in outsider

    get new_project_lot_path(@project, locale: :fr)
    assert_redirected_to root_path(locale: :fr)

    patch lot_path(lot, locale: :fr), params: { lot: { name: "Hack" } }
    assert_redirected_to root_path(locale: :fr)
    assert_not_equal "Hack", lot.reload.name
  end

  test "index et new des phases s'affichent, create fonctionne" do
    get project_phases_path(@project, locale: :fr)
    assert_response :success

    get new_project_phase_path(@project, locale: :fr)
    assert_response :success

    assert_difference -> { Phase.count } => 1 do
      post project_phases_path(@project, locale: :fr), params: { phase: { name: "Finitions", key: "finitions_bis" } }
    end
    assert_redirected_to project_phases_path(@project, locale: :fr)
  end

  test "modifier puis supprimer une phase" do
    phase = @project.phases.create!(name: "Chantier", key: "chantier", position: 0)

    get edit_phase_path(phase, locale: :fr)
    assert_response :success

    patch phase_path(phase, locale: :fr), params: { phase: { name: "Chantier — renommée" } }
    assert_equal "Chantier — renommée", phase.reload.name

    delete phase_path(phase, locale: :fr)
    assert_nil Phase.find_by(id: phase.id)
  end
end
