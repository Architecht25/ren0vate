require "test_helper"

class ComplianceAndWarrantiesSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users, :properties, :projects

  setup do
    @owner = users(:freemium_user)
    @owner.update_column(:onboarding_completed_at, 1.day.ago)
    @project = projects(:one)
    sign_in @owner
  end

  test "index et new des obligations s'affichent, create et update fonctionnent" do
    get project_compliance_items_path(@project, locale: :fr)
    assert_response :success

    get new_project_compliance_item_path(@project, locale: :fr)
    assert_response :success

    post project_compliance_items_path(@project, locale: :fr), params: { compliance_item: { label: "PEB", region: "wallonie", category: "peb" } }
    item = ComplianceItem.last
    assert_redirected_to project_compliance_items_path(@project, locale: :fr)

    patch compliance_item_path(item, locale: :fr), params: { status: "obtenu" }
    assert_equal "obtenu", item.reload.status
  end

  test "index et new des garanties s'affichent, create et destroy fonctionnent" do
    get project_warranties_path(@project, locale: :fr)
    assert_response :success

    get new_project_warranty_path(@project, locale: :fr)
    assert_response :success

    assert_difference -> { Warranty.count } => 1 do
      post project_warranties_path(@project, locale: :fr), params: { warranty: { label: "Toiture", start_date: Date.current, end_date: 10.years.from_now } }
    end

    warranty = Warranty.last
    delete warranty_path(warranty, locale: :fr)
    assert_nil Warranty.find_by(id: warranty.id)
  end
end
