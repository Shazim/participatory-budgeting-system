require "test_helper"

class BudgetPhasesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get budget_phases_index_url
    assert_response :success
  end

  test "should get show" do
    get budget_phases_show_url
    assert_response :success
  end

  test "should get new" do
    get budget_phases_new_url
    assert_response :success
  end

  test "should get create" do
    get budget_phases_create_url
    assert_response :success
  end

  test "should get edit" do
    get budget_phases_edit_url
    assert_response :success
  end

  test "should get update" do
    get budget_phases_update_url
    assert_response :success
  end

  test "should get destroy" do
    get budget_phases_destroy_url
    assert_response :success
  end

  test "should get transition" do
    get budget_phases_transition_url
    assert_response :success
  end
end
