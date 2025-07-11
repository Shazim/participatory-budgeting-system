require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_dashboard_index_url
    assert_response :success
  end

  test "should get analytics" do
    get admin_dashboard_analytics_url
    assert_response :success
  end

  test "should get reports" do
    get admin_dashboard_reports_url
    assert_response :success
  end
end
