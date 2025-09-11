require "test_helper"

class RequestProgressesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @property = properties(:one)
    @request = requests(:one)
    @prime = primes(:one)
    @request_progress = request_progresses(:one)
    sign_in @user
  end

  test "should get index" do
    get request_request_progresses_url(@request)
    assert_response :success
  end

  test "should get show" do
    get request_progress_url(@request_progress)
    assert_response :success
  end

  test "should get new" do
    get new_request_request_progress_url(@request)
    assert_response :success
  end

  test "should get edit" do
    get edit_request_progress_url(@request_progress)
    assert_response :success
  end

  test "should create request_progress" do
    assert_difference('RequestProgress.count') do
      post request_request_progresses_url(@request), params: {
        request_progress: {
          prime_id: @prime.id,
          step: "Test step",
          pourcentage: 50,
          status_administratif: "en_cours",
          montant_demande: 1000
        }
      }
    end

    assert_redirected_to request_progress_url(RequestProgress.last)
  end

  test "should update request_progress" do
    patch request_progress_url(@request_progress), params: {
      request_progress: {
        step: "Updated step",
        pourcentage: 75,
        status_administratif: "complet"
      }
    }
    assert_redirected_to request_progress_url(@request_progress)
  end

  test "should destroy request_progress" do
    assert_difference('RequestProgress.count', -1) do
      delete request_progress_url(@request_progress)
    end

    assert_redirected_to request_request_progresses_url(@request_progress.request)
  end
end
