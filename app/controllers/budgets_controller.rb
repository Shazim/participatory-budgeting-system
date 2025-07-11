class BudgetsController < ApplicationController
  before_action :set_budget, only: [:show, :edit, :update, :destroy, :activate, :close_voting]
  before_action :ensure_admin!, except: [:index, :show]

  def index
    @budgets = Budget.includes(:user, :budget_categories, :budget_phases)
                    .order(created_at: :desc)
                    .page(params[:page])

    @active_budgets = @budgets.active
    @draft_budgets = @budgets.where(status: 'draft')
    @completed_budgets = @budgets.where(status: 'completed')

    respond_to do |format|
      format.html
      format.json { render json: @budgets }
    end
  end

  def show
    @budget_categories = @budget.budget_categories.includes(:budget_projects)
    @budget_phases = @budget.budget_phases.chronological
    @current_phase = @budget.current_phase
    @next_phase = @budget.next_phase
    
    # Budget statistics
    @total_projects = @budget.budget_projects.count
    @approved_projects = @budget.budget_projects.approved.count
    @total_votes = @budget.votes.count
    @unique_voters = @budget.votes.distinct.count(:user_id)
    @total_allocated = @budget.total_allocated_amount
    @remaining_budget = @budget.remaining_amount
    
    # Category utilization
    @category_utilization = @budget.category_utilization
    
    # Voting statistics by phase
    @phase_stats = @budget_phases.map do |phase|
      {
        phase: phase,
        stats: Vote.phase_voting_stats(phase)
      }
    end

    # Top voted projects
    @top_projects = @budget.budget_projects
                          .joins(:votes)
                          .group('budget_projects.id')
                          .order('COUNT(votes.id) DESC')
                          .includes(:budget_category, :user)
                          .limit(5)

    respond_to do |format|
      format.html
      format.json { render json: budget_details }
    end
  end

  def new
    @budget = Budget.new
    @budget.budget_categories.build
  end

  def create
    @budget = current_user.budgets.build(budget_params)

    if @budget.save
      create_default_categories if params[:create_default_categories]
      redirect_to @budget, success: 'Budget was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @budget_categories = @budget.budget_categories
    @budget.budget_categories.build if @budget.budget_categories.empty?
  end

  def update
    if @budget.update(budget_params)
      redirect_to @budget, success: 'Budget was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @budget.destroy
    redirect_to budgets_path, success: 'Budget was successfully deleted.'
  end

  def activate
    if @budget.update(status: 'active')
      @budget.budget_phases.first&.update(status: 'active')
      redirect_to @budget, success: 'Budget has been activated.'
    else
      redirect_to @budget, alert: 'Could not activate budget.'
    end
  end

  def close_voting
    if @budget.update(status: 'voting_closed')
      redirect_to @budget, success: 'Voting has been closed for this budget.'
    else
      redirect_to @budget, alert: 'Could not close voting.'
    end
  end

  def categories
    @budget = Budget.find(params[:id])
    render json: @budget.budget_categories.select(:id, :name)
  end

  private

  def set_budget
    @budget = Budget.find(params[:id])
  end

  def budget_params
    params.require(:budget).permit(
      :title, :description, :total_amount, :start_date, :end_date, :status,
      budget_categories_attributes: [:id, :name, :description, :spending_limit_percentage, :_destroy]
    )
  end

  def create_default_categories
    default_categories = [
      { name: 'Infrastructure', description: 'Roads, buildings, and public facilities', spending_limit_percentage: 40 },
      { name: 'Social Programs', description: 'Education, healthcare, and community services', spending_limit_percentage: 30 },
      { name: 'Environment', description: 'Parks, green spaces, and environmental initiatives', spending_limit_percentage: 20 },
      { name: 'Technology', description: 'Digital infrastructure and innovation', spending_limit_percentage: 10 }
    ]

    default_categories.each do |category_attrs|
      @budget.budget_categories.create!(category_attrs)
    end
  end

  def budget_details
    {
      id: @budget.id,
      title: @budget.title,
      status: @budget.status,
      total_amount: @budget.total_amount,
      allocated_amount: @total_allocated,
      remaining_amount: @remaining_budget,
      progress_percentage: @budget.progress_percentage,
      current_phase: @current_phase&.name,
      total_projects: @total_projects,
      total_votes: @total_votes,
      unique_voters: @unique_voters,
      category_utilization: @category_utilization
    }
  end
end
