class VotesController < ApplicationController
  before_action :set_vote, only: [:update, :destroy, :edit]
  before_action :ensure_vote_owner, only: [:update, :destroy, :edit]

  def create
    @budget_project = BudgetProject.find(params[:budget_project_id])
    @current_phase = @budget_project.budget.current_phase

    unless @current_phase&.allows_voting?
      return handle_ajax_error('Voting is not allowed in the current phase.')
    end

    unless user_can_vote?(@budget_project)
      return handle_ajax_error('You cannot vote on this project.')
    end

    @vote = current_user.votes.build(vote_params)
    @vote.budget_project = @budget_project
    @vote.budget_phase = @current_phase

    if @vote.save
      @message = 'Your vote has been recorded successfully.'
      
      # Update project voting cache
      @voting_summary = Vote.voting_summary_for_project(@budget_project)
      
      respond_to do |format|
        format.html { redirect_to @budget_project, success: @message }
        format.json { 
          render json: { 
            success: true, 
            message: @message,
            vote: vote_json(@vote),
            voting_summary: @voting_summary,
            project_id: @budget_project.id
          }
        }
      end
    else
      error_message = @vote.errors.full_messages.join(', ')
      handle_ajax_error(error_message)
    end
  end

  def update
    if @vote.can_be_modified?
      if @vote.update(vote_params)
        @message = 'Your vote has been updated successfully.'
        @voting_summary = Vote.voting_summary_for_project(@vote.budget_project)
        
        respond_to do |format|
          format.html { redirect_to @vote.budget_project, success: @message }
          format.json { 
            render json: { 
              success: true, 
              message: @message,
              vote: vote_json(@vote),
              voting_summary: @voting_summary
            }
          }
        end
      else
        error_message = @vote.errors.full_messages.join(', ')
        handle_ajax_error(error_message)
      end
    else
      handle_ajax_error('This vote can no longer be modified.')
    end
  end

  def destroy
    budget_project = @vote.budget_project
    
    if @vote.can_be_modified?
      @vote.destroy
      @message = 'Your vote has been removed.'
      @voting_summary = Vote.voting_summary_for_project(budget_project)
      
      respond_to do |format|
        format.html { redirect_to budget_project, success: @message }
        format.json { 
          render json: { 
            success: true, 
            message: @message,
            voting_summary: @voting_summary,
            project_id: budget_project.id
          }
        }
      end
    else
      handle_ajax_error('This vote can no longer be removed.')
    end
  end

  def my_votes
    @votes = current_user.votes.includes(:budget_project, :budget_phase)
                        .order(created_at: :desc)
                        .page(params[:page])

    # Group votes by budget
    @votes_by_budget = @votes.group_by { |vote| vote.budget_project.budget }

    # User voting statistics
    @user_voting_stats = Vote.voting_summary_for_user(current_user)
    
    # Recent voting activity
    @recent_votes = @votes.limit(5)

    respond_to do |format|
      format.html
      format.json { render json: my_votes_data }
    end
  end

  def edit
    # The set_vote before_action already finds the vote
  end

  private

  def set_vote
    @vote = Vote.find(params[:id])
  end

  def ensure_vote_owner
    unless current_user == @vote.user
      redirect_to root_path, alert: 'Access denied.'
    end
  end

  def vote_params
    params.require(:vote).permit(:vote_weight)
  end

  def vote_json(vote)
    {
      id: vote.id,
      vote_weight: vote.vote_weight,
      weight_description: vote.weight_description,
      weight_color: vote.weight_color,
      created_at: vote.created_at.strftime('%B %d, %Y at %I:%M %p'),
      can_be_modified: vote.can_be_modified?
    }
  end

  def my_votes_data
    {
      total_votes: @votes.count,
      user_voting_stats: @user_voting_stats,
      votes: @votes.map do |vote|
        {
          id: vote.id,
          project_title: vote.budget_project.title,
          project_id: vote.budget_project.id,
          budget_title: vote.budget_project.budget.title,
          phase_name: vote.budget_phase.name,
          vote_weight: vote.vote_weight,
          weight_description: vote.weight_description,
          created_at: vote.created_at.strftime('%B %d, %Y'),
          can_be_modified: vote.can_be_modified?
        }
      end
    }
  end
end
