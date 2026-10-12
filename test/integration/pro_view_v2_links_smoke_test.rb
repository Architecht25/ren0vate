require "test_helper"

# V2 — Lot 4 : les pros (architecte/entrepreneur) n'avaient aucun moyen
# d'atteindre les fonctionnalités V2 (onglets ajoutés uniquement sur
# projects/show.html.erb, la vue propriétaire) — lien ajouté dans la
# sidebar pro (pro_views/_sidebar.html.erb). Placement provisoire, voir
# mémoire "project_v2_navigation_ia_decision".
class ProViewV2LinksSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users, :properties, :projects

  test "la vue pro affiche les liens vers les fonctionnalités V2 sans erreur" do
    owner = users(:freemium_user)
    project = projects(:one)

    architect = User.create!(email: "architect_proview@example.com", password: "password123", nom: "Architecte", onboarding_completed_at: 1.day.ago)
    project.project_members.create!(user: architect, role: "architect", status: "active")

    sign_in architect
    get pro_view_project_path(project, locale: :fr)

    assert_response :success
    assert_select "a[href=?]", project_project_documents_path(project, locale: :fr)
    assert_select "a[href=?]", project_message_threads_path(project, locale: :fr)
    assert_select "a[href=?]", project_schedule_items_path(project, locale: :fr)
  end
end
