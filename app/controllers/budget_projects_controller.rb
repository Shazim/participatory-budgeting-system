class BudgetProjectsController < ApplicationController
  before_action :set_budget_project, only: [:show, :edit, :update, :destroy, :vote, :approve, :reject, :voting_results]
  before_action :ensure_project_owner_or_admin, only: [:edit, :update, :destroy]
  before_action :ensure_admin!, only: [:approve, :reject]

  def index
    @budget_projects = BudgetProject.includes(:user, :budget_category, :votes, :impact_metric).all

    # Filtering
    if params[:budget_filter].present?
      @budget_projects = @budget_projects.joins(budget_category: :budget).where(budgets: { id: params[:budget_filter] })
    end
    if params[:category_filter].present?
      @budget_projects = @budget_projects.where(budget_category_id: params[:category_filter])
    end
    if params[:status_filter].present?
      @budget_projects = @budget_projects.where(status: params[:status_filter])
    end
    if params[:search].present?
      @budget_projects = @budget_projects.search_by_term(params[:search])
    end
    if params[:min_beneficiaries].present?
      @budget_projects = @budget_projects.min_beneficiaries(params[:min_beneficiaries])
    end
    if params[:max_timeline].present?
      @budget_projects = @budget_projects.max_timeline(params[:max_timeline])
    end
    if params[:min_sustainability].present?
      @budget_projects = @budget_projects.min_sustainability(params[:min_sustainability])
    end

    # Sorting
    case params[:sort_by]
    when 'votes'
      @budget_projects = @budget_projects.popular
    when 'amount'
      @budget_projects = @budget_projects.order(amount: :desc)
    when 'title'
      @budget_projects = @budget_projects.order(title: :asc)
    when 'sustainability'
      @budget_projects = @budget_projects.joins(:impact_metric).order('impact_metrics.sustainability_score DESC')
    when 'beneficiaries'
      @budget_projects = @budget_projects.joins(:impact_metric).order('impact_metrics.estimated_beneficiaries DESC')
    else
      @budget_projects = @budget_projects.recent
    end

    @budget_projects = @budget_projects.page(params[:page])

    # Statistics for sidebar
    @project_stats = {
      total: BudgetProject.count,
      pending: BudgetProject.pending.count,
      approved: BudgetProject.approved.count,
      rejected: BudgetProject.rejected.count
    }

    # Filter options
    @available_budgets = Budget.active.includes(:budget_categories)
    @available_categories = BudgetCategory.joins(:budget).where(budgets: { status: 'active' })

    respond_to do |format|
      format.html
      format.json { render json: @budget_projects }
    end
  end

  def show
    @impact_metric = @budget_project.impact_metric
    @votes = @budget_project.votes.includes(:user, :budget_phase).recent
    @user_vote = current_user.votes.find_by(budget_project: @budget_project)
    @voting_summary = Vote.voting_summary_for_project(@budget_project)
    
    # Related projects
    @related_projects = @budget_project.budget_category
                                      .budget_projects
                                      .where.not(id: @budget_project.id)
                                      .includes(:user, :impact_metric)
                                      .limit(3)

    # Check voting eligibility
    @can_vote = user_can_vote?(@budget_project)
    @current_phase = @budget_project.budget.current_phase

    respond_to do |format|
      format.html
      format.json { render json: project_details }
    end
  end

  def new
    @budget_category = BudgetCategory.find(params[:budget_category_id]) if params[:budget_category_id]
    @budget_project = BudgetProject.new(budget_category: @budget_category)
    @budget_project.build_impact_metric
    @available_categories = BudgetCategory.joins(:budget).where(budgets: { status: ['draft', 'active'] })
  end

  def create
    @budget_project = current_user.budget_projects.build(budget_project_params)
    
    if @budget_project.save
      redirect_to @budget_project, success: 'Project was successfully created.'
    else
      @available_categories = BudgetCategory.joins(:budget).where(budgets: { status: ['draft', 'active'] })
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @available_categories = BudgetCategory.joins(:budget).where(budgets: { status: ['draft', 'active'] })
    @impact_metric = @budget_project.impact_metric
  end

  def update
    if @budget_project.update(budget_project_params)
      redirect_to @budget_project, success: 'Project was successfully updated.'
    else
      @available_categories = BudgetCategory.joins(:budget).where(budgets: { status: ['draft', 'active'] })
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    budget_category = @budget_project.budget_category
    @budget_project.destroy
    redirect_to budget_projects_path, success: 'Project was successfully deleted.'
  end

  def vote
    current_phase = @budget_project.budget.current_phase
    
    unless current_phase&.allows_voting?
      return redirect_to @budget_project, alert: 'Voting is not allowed in the current phase.'
    end

    unless user_can_vote?(@budget_project)
      return redirect_to @budget_project, alert: 'You cannot vote on this project.'
    end

    @vote = current_user.votes.build(
      budget_project: @budget_project,
      budget_phase: current_phase,
      vote_weight: params[:vote_weight].to_f
    )

    if @vote.save
      @message = 'Your vote has been recorded successfully.'
      respond_to do |format|
        format.html { redirect_to @budget_project, success: @message }
        format.json { render json: { success: true, message: @message, vote: @vote } }
      end
    else
      error_message = @vote.errors.full_messages.join(', ')
      respond_to do |format|
        format.html { redirect_to @budget_project, alert: error_message }
        format.json { render json: { success: false, error: error_message }, status: :unprocessable_entity }
      end
    end
  end

  def approve
    if @budget_project.approve!
      redirect_to @budget_project, success: 'Project has been approved.'
    else
      redirect_to @budget_project, alert: 'Could not approve project. Check budget limits.'
    end
  end

  def reject
    reason = params[:reason]
    if @budget_project.reject!(reason)
      redirect_to @budget_project, success: 'Project has been rejected.'
    else
      redirect_to @budget_project, alert: 'Could not reject project.'
    end
  end

  def voting_results
    @voting_summary = Vote.voting_summary_for_project(@budget_project)
    @votes_by_phase = @budget_project.votes.includes(:budget_phase, :user).group_by(&:budget_phase)
    @vote_distribution = @budget_project.votes.group(:vote_weight).count

    respond_to do |format|
      format.html
      format.json { render json: @voting_summary }
    end
  end

  def preview_vote
    current_phase = @budget_project.budget.current_phase
    
    unless current_phase&.allows_voting?
      return render json: { valid: false, message: 'Voting is not allowed in the current phase.' }
    end
    
    if current_user.has_voted_for?(@budget_project)
      return render json: { valid: true, message: 'You have already voted, but you can change your vote.' }
    end

    vote = Vote.new(
      user: current_user,
      budget_project: @budget_project,
      budget_phase: current_phase,
      vote_weight: params[:vote_weight].to_f
    )

    if vote.valid?
      render json: { valid: true, message: 'This vote is valid.' }
    else
      render json: { valid: false, message: vote.errors.full_messages.join(', ') }
    end
  end

  private

  def set_budget_project
    @budget_project = BudgetProject.find(params[:id])
  end

  def ensure_project_owner_or_admin
    unless current_user.admin? || @budget_project.user == current_user
      redirect_to @budget_project, alert: 'Access denied.'
    end
  end

  def budget_project_params
    params.require(:budget_project).permit(
      :title, :description, :amount, :budget_category_id, :status,
      impact_metric_attributes: [
        :id, :estimated_beneficiaries, :timeline_months, :sustainability_score,
        :environmental_impact, :social_impact, :economic_impact
      ]
    )
  end

  def project_details
    {
      id: @budget_project.id,
      title: @budget_project.title,
      amount: @budget_project.amount,
      status: @budget_project.status,
      votes_count: @budget_project.vote_count,
      average_vote_weight: @budget_project.average_vote_weight,
      approval_rate: @budget_project.approval_rate,
      impact_score: @budget_project.impact_score,
      can_vote: @can_vote,
      user_has_voted: @user_vote.present?,
      current_phase: @current_phase&.name,
      voting_summary: @voting_summary
    }
  end
end
