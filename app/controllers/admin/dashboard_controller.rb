class Admin::DashboardController < ApplicationController
  def index
    @stats = {
      total_budgets: Budget.count,
      total_projects: BudgetProject.count,
      total_users: User.count,
      total_votes: Vote.count
    }
  end

  def analytics
    @votes_by_category = BudgetCategory.joins(:votes).group(:name).count
    @projects_by_status = BudgetProject.group(:status).count
    @budget_allocation = BudgetCategory.group(:name).sum(:spending_limit_percentage)
  end

  def phase_analytics
    @budgets = Budget.includes(:budget_phases).all
    if params[:budget_id].present?
      @selected_budget = Budget.find(params[:budget_id])
      @phase_stats = @selected_budget.budget_phases.map do |phase|
        {
          phase: phase,
          stats: Vote.phase_voting_stats(phase)
        }
      end
    end
  end

  def reports
    respond_to do |format|
      format.html
      format.csv do
        send_data generate_csv_report, filename: "#{params[:report_type]}-#{Date.today}.csv"
      end
    end
  end

  def category_monitoring
    @budgets = Budget.includes(budget_categories: { budget_projects: :votes }).all
  end

  private

  def generate_csv_report
    case params[:report_type]
    when "all_projects"
      BudgetProject.to_csv
    when "voting_results"
      Vote.to_csv
    when "user_list"
      User.to_csv
    when "budget_utilization"
      Budget.to_csv
    when "impact_report"
      BudgetProject.to_csv_with_impact
    else
      # Handle invalid report type
      ""
    end
  end
end
