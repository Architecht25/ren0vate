require "test_helper"

class ComplianceItemPolicyTest < ActiveSupport::TestCase
  fixtures :users, :properties, :projects

  setup do
    @owner = users(:freemium_user)
    @project = projects(:one)
    @architect = User.create!(email: "architect_compliance@example.com", password: "password123", nom: "Architecte")
    @project.project_members.create!(user: @architect, role: "architect", status: "active")
    @roofer = User.create!(email: "roofer_compliance@example.com", password: "password123", nom: "Couvreur")
    @project.project_members.create!(user: @roofer, role: "entrepreneur", status: "active")

    @item = @project.compliance_items.create!(label: "Permis", region: "wallonie", category: "permis")
  end

  test "tout membre actif voit les obligations, pas scopées par lot" do
    assert ComplianceItemPolicy.new(@roofer, @item).show?
  end

  test "seuls le propriétaire et l'architecte gèrent les obligations" do
    assert ComplianceItemPolicy.new(@owner, @item).create?
    assert ComplianceItemPolicy.new(@architect, @item).create?
    assert_not ComplianceItemPolicy.new(@roofer, @item).create?
  end
end
