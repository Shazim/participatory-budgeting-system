class HomeController < ApplicationController
  include ActionView::Helpers::NumberHelper

  def index
    if user_signed_in?
      redirect_to dashboard_path
    else
      @active_budgets = Budget.active.includes(:budget_categories).limit(3)
      @total_budgets = Budget.count
      @total_projects = BudgetProject.count
      @total_votes = Vote.count
    end
  end

  def dashboard
    @active_budgets = Budget.active.includes(:budget_categories, :budget_phases, :budget_projects)
    @user_votes = current_user.votes.includes(:budget_project, :budget_phase).recent.limit(5)
    @user_projects = current_user.budget_projects.includes(:budget_category, :votes).recent.limit(5)

    # Statistics for current user
    @user_stats = {
      total_votes: current_user.votes.count,
      total_projects: current_user.budget_projects.count,
      projects_approved: current_user.budget_projects.approved.count,
      vote_weight_avg: current_user.votes.average(:vote_weight)&.round(2) || 0
    }

    # Current active phase information
    @current_phases = BudgetPhase.active.includes(:budget).limit(3)

    # Recent activity
    @recent_projects = BudgetProject.includes(:user, :budget_category)
                                  .joins(budget_category: :budget)
                                  .where(budgets: { status: "active" })
                                  .recent.limit(5)

    # Budget utilization overview
    @budget_utilizations = @active_budgets.map do |budget|
      {
        budget: budget,
        utilization: budget.category_utilization
      }
    end

    # Voting opportunities
    @voting_opportunities = BudgetProject.votable
                                       .joins(budget_category: :budget)
                                       .where(budgets: { status: "active" })
                                       .where.not(id: current_user.votes.select(:budget_project_id))
                                       .includes(:budget_category, :impact_metric)
                                       .limit(5)

    respond_to do |format|
      format.html
      format.json { render json: dashboard_data }
    end
  end

  private

  def dashboard_data
    {
      user_stats: @user_stats,
      active_budgets_count: @active_budgets.count,
      voting_opportunities_count: @voting_opportunities.count,
      current_phases: @current_phases.map do |phase|
        {
          id: phase.id,
          name: phase.name,
          budget_name: phase.budget.title,
          status: phase.status,
          progress: phase.progress_percentage,
          days_remaining: phase.days_remaining
        }
      end
    }
  end
end
