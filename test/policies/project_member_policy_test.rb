require "test_helper"

class ProjectMemberPolicyTest < ActiveSupport::TestCase
  fixtures :users, :properties, :projects

  setup do
    @owner = users(:freemium_user)
    @project = projects(:one)
    @architect = User.create!(email: "architect@example.com", password: "password123", nom: "Architecte")
    @membership = @project.project_members.create!(user: @architect, role: "architect", status: "active")
    @outsider = User.create!(email: "outsider@example.com", password: "password123", nom: "Outsider")
  end

  test "le propriétaire gère les intervenants" do
    policy = ProjectMemberPolicy.new(@owner, @membership)
    assert policy.show?
    assert policy.create?
    assert policy.update?
    assert policy.destroy?
  end

  test "un intervenant peut voir sa propre adhésion mais pas la gérer" do
    policy = ProjectMemberPolicy.new(@architect, @membership)
    assert policy.show?
    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "un tiers ne voit pas l'adhésion d'un autre intervenant" do
    policy = ProjectMemberPolicy.new(@outsider, @membership)
    assert_not policy.show?
  end
end
