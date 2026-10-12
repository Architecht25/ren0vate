require "test_helper"

class ProjectPolicyTest < ActiveSupport::TestCase
  fixtures :users, :properties, :projects

  setup do
    @owner = users(:freemium_user)
    @project = projects(:one)
    @outsider = User.create!(email: "outsider@example.com", password: "password123", nom: "Outsider")
    @architect = User.create!(email: "architect@example.com", password: "password123", nom: "Architecte")
    @project.project_members.create!(user: @architect, role: "architect", status: "active")
  end

  test "le propriétaire peut tout faire sur son chantier" do
    policy = ProjectPolicy.new(@owner, @project)
    assert policy.show?
    assert policy.update?
    assert policy.destroy?
    assert policy.manage_members?
  end

  test "un membre actif peut voir le chantier mais pas le gérer" do
    policy = ProjectPolicy.new(@architect, @project)
    assert policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
    assert_not policy.manage_members?
  end

  test "un utilisateur sans lien avec le chantier n'a aucun accès" do
    policy = ProjectPolicy.new(@outsider, @project)
    assert_not policy.show?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "un membre en attente d'acceptation n'a pas encore accès" do
    pending_user = User.create!(email: "pending@example.com", password: "password123", nom: "En attente")
    @project.project_members.create!(user: pending_user, role: "entrepreneur", status: "pending")

    policy = ProjectPolicy.new(pending_user, @project)
    assert_not policy.show?
  end

  test "le scope ne retourne que les chantiers possédés ou où l'utilisateur est membre actif" do
    scope = ProjectPolicy::Scope.new(@architect, Project).resolve
    assert_includes scope, @project
    assert_not_includes ProjectPolicy::Scope.new(@outsider, Project).resolve, @project
  end
end
