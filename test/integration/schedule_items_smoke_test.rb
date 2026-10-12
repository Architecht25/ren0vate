require "test_helper"

class ScheduleItemsSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users, :properties, :projects

  setup do
    @owner = users(:freemium_user)
    @owner.update_column(:onboarding_completed_at, 1.day.ago)
    @project = projects(:one)
    sign_in @owner
  end

  test "index et new s'affichent, create fonctionne" do
    get project_schedule_items_path(@project, locale: :fr)
    assert_response :success

    get new_project_schedule_item_path(@project, locale: :fr)
    assert_response :success

    assert_difference -> { ScheduleItem.count } => 1 do
      post project_schedule_items_path(@project, locale: :fr), params: { schedule_item: { label: "Démolition" } }
    end
  end

  test "changer le statut puis supprimer" do
    item = @project.schedule_items.create!(label: "Test")

    patch schedule_item_path(item, locale: :fr), params: { status: "en_cours" }
    assert_equal "en_cours", item.reload.status

    delete schedule_item_path(item, locale: :fr)
    assert_nil ScheduleItem.find_by(id: item.id)
  end
end
