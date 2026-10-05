require "test_helper"

# Non-régression : la home ne doit pas renvoyer 500 quand la base est injoignable
# (incident Sentry 405d445598e048bdbdf6a039372ab2c1 — PG::ConnectionBad sur PagesController#home).
class HomeDbOutageSmokeTest < ActionDispatch::IntegrationTest
  test "home renders when Project.count cannot reach the database" do
    Project.define_singleton_method(:count) { |*| raise ActiveRecord::ConnectionNotEstablished, "connection refused" }
    begin
      get root_path
    ensure
      Project.singleton_class.send(:remove_method, :count)
    end

    assert_response :success
  end

  test "home renders normally" do
    get root_path
    assert_response :success
  end
end
