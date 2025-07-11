class Admin::BudgetCategoriesController < ApplicationController
  before_action :set_budget_category, only: [ :edit, :update ]

  def index
    @budget_categories = BudgetCategory.includes(:budget).all
  end

  def edit
  end

  def update
    if @budget_category.update(budget_category_params)
      redirect_to admin_budget_categories_path, notice: "Category limit updated successfully."
    else
      render :edit
    end
  end

  private

  def set_budget_category
    @budget_category = BudgetCategory.find(params[:id])
  end

  def budget_category_params
    params.require(:budget_category).permit(:spending_limit_percentage)
  end
end
