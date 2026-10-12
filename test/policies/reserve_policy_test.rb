require "test_helper"

class ReservePolicyTest < ActiveSupport::TestCase
  fixtures :users, :properties, :projects

  setup do
    @owner = users(:freemium_user)
    @project = projects(:one)
    @toiture = @project.lots.create!(key: "toiture", name: "Toiture", position: 0)
    @menuiseries = @project.lots.create!(key: "menuiseries", name: "Menuiseries", position: 1)

    @roofer = User.create!(email: "roofer_reserve@example.com", password: "password123", nom: "Couvreur")
    roofer_membership = @project.project_members.create!(user: @roofer, role: "entrepreneur", status: "active")
    roofer_membership.project_member_lots.create!(lot: @toiture)

    @architect = User.create!(email: "architect_reserve@example.com", password: "password123", nom: "Architecte")
    @project.project_members.create!(user: @architect, role: "architect", status: "active")

    @reserve_toiture = @project.reserves.create!(description: "Fuite au faîtage", lot: @toiture)
  end

  test "le propriétaire et l'architecte (non scopé) voient toutes les réserves" do
    assert ReservePolicy.new(@owner, @reserve_toiture).show?
    assert ReservePolicy.new(@architect, @reserve_toiture).show?
  end

  test "un entrepreneur scopé à un lot ne voit que les réserves de ce lot" do
    assert ReservePolicy.new(@roofer, @reserve_toiture).show?

    other_roofer = User.create!(email: "other_roofer_reserve@example.com", password: "password123", nom: "Autre couvreur")
    @project.project_members.create!(user: other_roofer, role: "entrepreneur", status: "active").project_member_lots.create!(lot: @menuiseries)
    assert_not ReservePolicy.new(other_roofer, @reserve_toiture).show?
  end

  test "seul le propriétaire peut supprimer une réserve" do
    assert ReservePolicy.new(@owner, @reserve_toiture).destroy?
    assert_not ReservePolicy.new(@architect, @reserve_toiture).destroy?
    assert_not ReservePolicy.new(@roofer, @reserve_toiture).destroy?
  end

  test "une réserve sans lot reste visible de tout membre actif (comportement V1 préservé)" do
    reserve_sans_lot = @project.reserves.create!(description: "Défaut général")
    other_roofer = User.create!(email: "general_roofer@example.com", password: "password123", nom: "Couvreur général")
    @project.project_members.create!(user: other_roofer, role: "entrepreneur", status: "active").project_member_lots.create!(lot: @menuiseries)

    assert ReservePolicy.new(other_roofer, reserve_sans_lot).show?
  end
end
