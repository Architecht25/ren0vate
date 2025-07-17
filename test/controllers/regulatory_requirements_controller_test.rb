require "test_helper"

class RegulatoryRequirementsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get regulatory_requirements_index_url
    assert_response :success
  end

  test "should get ventilation_guide" do
    get regulatory_requirements_ventilation_guide_url
    assert_response :success
  end
end
