require "test_helper"

class WarrantyPolicyTest < ActiveSupport::TestCase
  fixtures :users, :properties, :projects

  setup do
    @owner = users(:freemium_user)
    @project = projects(:one)
    @toiture = @project.lots.create!(key: "toiture", name: "Toiture", position: 0)
    @menuiseries = @project.lots.create!(key: "menuiseries", name: "Menuiseries", position: 1)

    @roofer = User.create!(email: "roofer_warranty@example.com", password: "password123", nom: "Couvreur")
    @project.project_members.create!(user: @roofer, role: "entrepreneur", status: "active").project_member_lots.create!(lot: @toiture)

    @warranty = @project.warranties.create!(label: "Garantie toiture", lot: @toiture, start_date: Date.current, end_date: 10.years.from_now)
  end

  test "un entrepreneur scopé voit la garantie de son lot, pas celle d'un autre" do
    assert WarrantyPolicy.new(@roofer, @warranty).show?

    other_roofer = User.create!(email: "other_roofer_warranty@example.com", password: "password123", nom: "Menuisier")
    @project.project_members.create!(user: other_roofer, role: "entrepreneur", status: "active").project_member_lots.create!(lot: @menuiseries)
    assert_not WarrantyPolicy.new(other_roofer, @warranty).show?
  end

  test "un entrepreneur ne peut pas créer de garantie" do
    assert_not WarrantyPolicy.new(@roofer, @warranty).create?
  end
end
