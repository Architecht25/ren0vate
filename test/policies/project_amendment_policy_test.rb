require "test_helper"

class ProjectAmendmentPolicyTest < ActiveSupport::TestCase
  fixtures :users, :properties, :projects

  setup do
    @owner = users(:freemium_user)
    @project = projects(:one)
    @architect = User.create!(email: "architect_amendment@example.com", password: "password123", nom: "Architecte")
    @project.project_members.create!(user: @architect, role: "architect", status: "active")
    @outsider = User.create!(email: "outsider_amendment@example.com", password: "password123", nom: "Outsider")

    @amendment = @project.project_amendments.create!(motif: "Isolation supplémentaire", delta_montant: 1500, requested_by: @architect)
  end

  test "un membre actif peut proposer, seul le propriétaire décide" do
    assert ProjectAmendmentPolicy.new(@architect, @amendment).create?
    assert_not ProjectAmendmentPolicy.new(@architect, @amendment).decide?
    assert ProjectAmendmentPolicy.new(@owner, @amendment).decide?
  end

  test "un tiers hors chantier n'a aucun accès" do
    assert_not ProjectAmendmentPolicy.new(@outsider, @amendment).show?
    assert_not ProjectAmendmentPolicy.new(@outsider, @amendment).create?
  end

  test "decide! trace qui a validé et quand" do
    @amendment.decide!(status: "valide", by: @owner)
    assert @amendment.valide?
    assert_equal @owner, @amendment.validated_by
    assert @amendment.validated_at.present?
  end
end
