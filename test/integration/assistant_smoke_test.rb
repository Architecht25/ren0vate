require "test_helper"

class AssistantSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users, :properties, :projects

  setup do
    @owner = users(:freemium_user)
    @owner.update_column(:onboarding_completed_at, 1.day.ago)
    @project = projects(:one)
    sign_in @owner
  end

  test "la page s'affiche sans erreur et poser une question ne plante pas sans clé API" do
    get project_assistant_path(@project, locale: :fr)
    assert_response :success

    post project_assistant_path(@project, locale: :fr), params: { question: "Quelle garantie sur la toiture ?" }
    assert_response :success
    assert_select "p", text: /Quelle garantie sur la toiture/
  end

  test "un tiers hors chantier ne peut pas accéder à l'assistant" do
    outsider = User.create!(email: "outsider_assistant@example.com", password: "password123", nom: "Outsider")
    outsider.update_column(:onboarding_completed_at, 1.day.ago)
    sign_out @owner
    sign_in outsider

    get project_assistant_path(@project, locale: :fr)
    assert_redirected_to root_path(locale: :fr)
  end
end
