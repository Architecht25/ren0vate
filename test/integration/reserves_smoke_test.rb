require "test_helper"

# V2 — Lot 4 : ReservesController n'avait aucun test avant ce lot (gap
# repéré en branchant Pundit dessus). Couvre le comportement V1 existant
# (create/update/destroy) + le nouveau périmètre de lot.
class ReservesSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users, :properties, :projects

  setup do
    @owner = users(:freemium_user)
    @owner.update_column(:onboarding_completed_at, 1.day.ago)
    @project = projects(:one)
    @toiture = @project.lots.create!(key: "toiture", name: "Toiture", position: 0)
  end

  test "le propriétaire peut créer une réserve avec un lot" do
    sign_in @owner

    assert_difference -> { Reserve.count } => 1 do
      post project_reserves_path(@project, locale: :fr), params: {
        reserve: { description: "Fissure plafond", lot_id: @toiture.id }
      }
    end

    reserve = Reserve.last
    assert_equal @toiture, reserve.lot
    assert_redirected_to reception_chantier_project_path(@project, locale: :fr, anchor: "reserves")
  end

  test "un entrepreneur scopé à un autre lot ne peut pas modifier une réserve hors de son périmètre" do
    menuiseries = @project.lots.create!(key: "menuiseries", name: "Menuiseries", position: 1)
    reserve = @project.reserves.create!(description: "Fuite", lot: @toiture)

    roofer = User.create!(email: "scoped_roofer@example.com", password: "password123", nom: "Couvreur")
    @project.project_members.create!(user: roofer, role: "entrepreneur", status: "active").project_member_lots.create!(lot: menuiseries)
    roofer.update_column(:onboarding_completed_at, 1.day.ago)
    sign_in roofer

    patch project_reserve_path(@project, reserve, locale: :fr), params: { reserve: { description: "Modifié" } }

    assert_redirected_to root_path(locale: :fr)
    assert_not_equal "Modifié", reserve.reload.description
  end

  test "seul le propriétaire peut supprimer une réserve" do
    reserve = @project.reserves.create!(description: "Fuite", lot: @toiture)
    architect = User.create!(email: "architect_del@example.com", password: "password123", nom: "Architecte")
    @project.project_members.create!(user: architect, role: "architect", status: "active")
    architect.update_column(:onboarding_completed_at, 1.day.ago)
    sign_in architect

    delete project_reserve_path(@project, reserve, locale: :fr)

    assert_redirected_to root_path(locale: :fr)
    assert Reserve.exists?(reserve.id)
  end
end
