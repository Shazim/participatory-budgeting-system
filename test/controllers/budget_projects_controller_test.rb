require "test_helper"

class BudgetProjectsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get budget_projects_index_url
    assert_response :success
  end

  test "should get show" do
    get budget_projects_show_url
    assert_response :success
  end

  test "should get new" do
    get budget_projects_new_url
    assert_response :success
  end

  test "should get create" do
    get budget_projects_create_url
    assert_response :success
  end

  test "should get edit" do
    get budget_projects_edit_url
    assert_response :success
  end

  test "should get update" do
    get budget_projects_update_url
    assert_response :success
  end

  test "should get destroy" do
    get budget_projects_destroy_url
    assert_response :success
  end

  test "should get vote" do
    get budget_projects_vote_url
    assert_response :success
  end
end
