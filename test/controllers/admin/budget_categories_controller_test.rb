require "test_helper"

class Admin::BudgetCategoriesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_budget_categories_index_url
    assert_response :success
  end

  test "should get edit" do
    get admin_budget_categories_edit_url
    assert_response :success
  end

  test "should get update" do
    get admin_budget_categories_update_url
    assert_response :success
  end
end
