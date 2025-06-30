require "test_helper"

class PrimesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get primes_index_url
    assert_response :success
  end

  test "should get show" do
    get primes_show_url
    assert_response :success
  end
end
