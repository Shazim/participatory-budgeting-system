require "test_helper"

class ImpactMetricsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get impact_metrics_show_url
    assert_response :success
  end

  test "should get edit" do
    get impact_metrics_edit_url
    assert_response :success
  end

  test "should get update" do
    get impact_metrics_update_url
    assert_response :success
  end
end
