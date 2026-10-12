require "test_helper"

class SiteLogEntriesSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users, :properties, :projects

  setup do
    @owner = users(:freemium_user)
    @owner.update_column(:onboarding_completed_at, 1.day.ago)
    @project = projects(:one)
    sign_in @owner
  end

  test "index et new s'affichent sans erreur" do
    get project_site_log_entries_path(@project, locale: :fr)
    assert_response :success

    get new_project_site_log_entry_path(@project, locale: :fr)
    assert_response :success
  end

  test "créer une observation fonctionne" do
    assert_difference -> { SiteLogEntry.count } => 1 do
      post project_site_log_entries_path(@project, locale: :fr), params: {
        site_log_entry: { body: "Démarrage du chantier" }
      }
    end

    entry = SiteLogEntry.last
    assert_equal @owner, entry.author
    assert_redirected_to project_site_log_entries_path(@project, locale: :fr)
  end

  test "supprimer une observation fonctionne" do
    entry = @project.site_log_entries.create!(body: "Test", author: @owner, observed_at: Time.current)

    delete site_log_entry_path(entry, locale: :fr)

    assert_nil SiteLogEntry.find_by(id: entry.id)
  end
end
