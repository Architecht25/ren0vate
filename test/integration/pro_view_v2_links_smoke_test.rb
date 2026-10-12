require "test_helper"

# V2 — les pros (architecte/entrepreneur) n'avaient aucun moyen d'atteindre
# les fonctionnalités V2 (onglets ajoutés uniquement sur
# projects/show.html.erb, la vue propriétaire) — liens ajoutés dans la
# sidebar pro (pro_views/_sidebar.html.erb). Placement provisoire, voir
# mémoire "project_v2_navigation_ia_decision". Les 12 fonctionnalités V2
# (Lots 0-6) doivent toutes y figurer, pas seulement les premières ajoutées
# (gap repéré par Robin le 12/10/2026 — 6 sur 12 manquaient).
class ProViewV2LinksSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users, :properties, :projects

  test "la vue pro affiche les liens vers les 12 fonctionnalités V2 sans erreur" do
    owner = users(:freemium_user)
    project = projects(:one)

    architect = User.create!(email: "architect_proview@example.com", password: "password123", nom: "Architecte", onboarding_completed_at: 1.day.ago)
    project.project_members.create!(user: architect, role: "architect", status: "active")

    sign_in architect
    get pro_view_project_path(project, locale: :fr)

    assert_response :success
    [
      project_project_documents_path(project, locale: :fr),
      project_project_quotes_path(project, locale: :fr),
      project_project_amendments_path(project, locale: :fr),
      project_lots_path(project, locale: :fr),
      project_phases_path(project, locale: :fr),
      project_site_log_entries_path(project, locale: :fr),
      project_message_threads_path(project, locale: :fr),
      project_schedule_items_path(project, locale: :fr),
      project_assistant_path(project, locale: :fr),
      project_compliance_items_path(project, locale: :fr),
      project_warranties_path(project, locale: :fr),
      project_vault_path(project, locale: :fr)
    ].each do |path|
      assert_select "a[href=?]", path
    end
  end
end
