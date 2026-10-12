require "test_helper"

class LotPolicyTest < ActiveSupport::TestCase
  fixtures :users, :properties, :projects

  setup do
    @owner = users(:freemium_user)
    @project = projects(:one)
    @toiture = @project.lots.create!(key: "toiture", name: "Toiture", position: 0)
    @menuiseries = @project.lots.create!(key: "menuiseries", name: "Menuiseries", position: 1)

    @architect = User.create!(email: "architect@example.com", password: "password123", nom: "Architecte")
    @project.project_members.create!(user: @architect, role: "architect", status: "active")

    @roofer = User.create!(email: "roofer@example.com", password: "password123", nom: "Couvreur")
    roofer_membership = @project.project_members.create!(user: @roofer, role: "entrepreneur", status: "active")
    roofer_membership.project_member_lots.create!(lot: @toiture)
  end

  test "le propriétaire voit tous les lots et peut les gérer" do
    assert LotPolicy.new(@owner, @toiture).show?
    assert LotPolicy.new(@owner, @menuiseries).show?
    assert LotPolicy.new(@owner, @toiture).create?
    assert LotPolicy.new(@owner, @toiture).destroy?
  end

  test "un membre sans périmètre explicite voit tous les lots du chantier (défaut non restrictif)" do
    assert LotPolicy.new(@architect, @toiture).show?
    assert LotPolicy.new(@architect, @menuiseries).show?
  end

  test "un membre ne peut pas gérer les lots, même s'il les voit" do
    assert_not LotPolicy.new(@architect, @toiture).create?
    assert_not LotPolicy.new(@architect, @toiture).update?
    assert_not LotPolicy.new(@architect, @toiture).destroy?
  end

  test "un entrepreneur scopé à un lot ne voit que ce lot — c'est la règle de sécurité centrale du §3" do
    assert LotPolicy.new(@roofer, @toiture).show?
    assert_not LotPolicy.new(@roofer, @menuiseries).show?
  end

  test "le scope reflète le périmètre de lots, pas seulement l'appartenance au chantier" do
    scope = LotPolicy::Scope.new(@roofer, Lot).resolve
    assert_includes scope, @toiture
    assert_not_includes scope, @menuiseries
  end
end
