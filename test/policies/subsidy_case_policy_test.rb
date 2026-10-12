require "test_helper"

class SubsidyCasePolicyTest < ActiveSupport::TestCase
  fixtures :users, :properties, :projects

  test "une simulation anonyme est visible par tout le monde (pas de compte)" do
    anonymous_case = SubsidyCase.create!(region: "wallonie", mode: "simulation", input_data: {})
    outsider = User.create!(email: "outsider_subsidy@example.com", password: "password123", nom: "Outsider")

    assert SubsidyCasePolicy.new(nil, anonymous_case).show?
    assert SubsidyCasePolicy.new(outsider, anonymous_case).show?
  end

  test "une simulation liée à un compte n'est visible que par son auteur" do
    owner = users(:freemium_user)
    outsider = User.create!(email: "outsider_subsidy2@example.com", password: "password123", nom: "Outsider")
    own_case = SubsidyCase.create!(region: "wallonie", mode: "simulation", user: owner, input_data: {})

    assert SubsidyCasePolicy.new(owner, own_case).show?
    assert_not SubsidyCasePolicy.new(outsider, own_case).show?
  end

  test "un dossier rattaché à un chantier suit les règles d'accès du projet" do
    project = projects(:one)
    dossier_case = SubsidyCase.create!(region: "wallonie", mode: "dossier", project: project, input_data: {})
    outsider = User.create!(email: "outsider_subsidy3@example.com", password: "password123", nom: "Outsider")

    assert SubsidyCasePolicy.new(project.user, dossier_case).show?
    assert_not SubsidyCasePolicy.new(outsider, dossier_case).show?
  end

  test "create? est toujours vrai — la simulation est publique" do
    assert SubsidyCasePolicy.new(nil, SubsidyCase.new).create?
  end
end
