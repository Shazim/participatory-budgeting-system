require 'csv'

class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :budget_project
  belongs_to :budget_phase

  # Validations
  validates :user_id, uniqueness: { 
    scope: [:budget_project_id, :budget_phase_id], 
    message: "has already voted for this project in this phase" 
  }
  validates :vote_weight, presence: true, 
            numericality: { 
              greater_than: -10, 
              less_than_or_equal_to: 10,
              message: "must be between -10 and 10"
            }
  validate :voting_allowed_in_current_phase
  validate :project_votable
  validate :user_eligible_to_vote
  validate :category_budget_not_exceeded, on: :create

  # Scopes
  scope :positive, -> { where('vote_weight > 0') }
  scope :negative, -> { where('vote_weight < 0') }
  scope :neutral, -> { where(vote_weight: 0) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_weight, -> { order(vote_weight: :desc) }
  scope :for_budget, ->(budget) { joins(budget_project: { budget_category: :budget }).where(budgets: { id: budget.id }) }
  scope :for_phase, ->(phase) { where(budget_phase: phase) }

  # Callbacks
  after_create :update_project_vote_cache
  after_update :update_project_vote_cache
  after_destroy :update_project_vote_cache

  # Instance methods
  def positive?
    vote_weight > 0
  end

  def negative?
    vote_weight < 0
  end

  def neutral?
    vote_weight == 0
  end

  def weight_description
    case vote_weight
    when -10..-8
      "Strongly Oppose"
    when -7..-5
      "Oppose"
    when -4..-1
      "Slightly Oppose"
    when 0
      "Neutral"
    when 1..4
      "Slightly Support"
    when 5..7
      "Support"
    when 8..10
      "Strongly Support"
    else
      "Unknown"
    end
  end

  def weight_color
    case vote_weight
    when -10..-6
      'danger'
    when -5..-1
      'warning'
    when 0
      'secondary'
    when 1..5
      'info'
    when 6..10
      'success'
    else
      'light'
    end
  end

  def can_be_modified?
    return false unless budget_phase.active?
    return false unless budget_project.can_be_voted_on?
    
    # Allow modification within 24 hours of creation
    created_at > 24.hours.ago
  end

  def update_weight!(new_weight)
    return false unless can_be_modified?
    
    update!(vote_weight: new_weight)
  end

  def voter_name
    user.full_name
  end

  def project_title
    budget_project.title
  end

  def phase_name
    budget_phase.name
  end

  def vote_type
    return 'positive' if positive?
    return 'negative' if negative?
    'neutral'
  end

  # Class methods
  def self.voting_summary_for_project(project)
    votes = where(budget_project: project)
    
    {
      total_votes: votes.count,
      positive_votes: votes.positive.count,
      negative_votes: votes.negative.count,
      neutral_votes: votes.neutral.count,
      average_weight: votes.average(:vote_weight)&.round(2) || 0,
      total_weight: votes.sum(:vote_weight) || 0
    }
  end

  def self.voting_summary_for_user(user, budget = nil)
    votes = user.votes
    votes = votes.joins(budget_project: { budget_category: :budget }).where(budgets: { id: budget.id }) if budget
    
    {
      total_votes: votes.count,
      positive_votes: votes.positive.count,
      negative_votes: votes.negative.count,
      neutral_votes: votes.neutral.count,
      average_weight: votes.average(:vote_weight)&.round(2) || 0,
      last_vote_date: votes.maximum(:created_at)
    }
  end

  def self.phase_voting_stats(budget_phase)
    votes = where(budget_phase: budget_phase)
    
    {
      total_votes: votes.count,
      unique_voters: votes.distinct.count(:user_id),
      projects_voted_on: votes.distinct.count(:budget_project_id),
      average_weight: votes.average(:vote_weight)&.round(2) || 0,
      participation_rate: calculate_participation_rate(budget_phase)
    }
  end

  private

  def category_budget_not_exceeded
    return unless positive?

    project = self.budget_project
    category = project.budget_category
    
    # Check if the project is moving from unfunded to funded status with this vote
    is_newly_funded = project.total_vote_weight <= 0 && (project.total_vote_weight + self.vote_weight) > 0

    return unless is_newly_funded

    # Calculate remaining budget for provisionally funded projects
    provisional_remaining = category.spending_limit_amount - (category.total_allocated_amount + category.provisionally_funded_projects_amount)

    if project.amount > provisional_remaining
      errors.add(:base, "This vote cannot be cast as it would exceed the '#{category.name}' category budget limit.")
    end
  end

  def voting_allowed_in_current_phase
    unless budget_phase.allows_voting?
      errors.add(:base, "Voting is not allowed in the current phase")
    end
  end

  def project_votable
    unless budget_project.can_be_voted_on?
      errors.add(:budget_project, "cannot be voted on at this time")
    end
  end

  def user_eligible_to_vote
    # For now, all users are eligible. This can be expanded later.
    true
  end

  def update_project_vote_cache
    # Update any cached vote counts or scores
    budget_project.touch
  end

  def self.calculate_participation_rate(budget_phase)
    eligible_users = User.participant.count
    return 0 if eligible_users == 0
    
    voters = where(budget_phase: budget_phase).distinct.count(:user_id)
    (voters.to_f / eligible_users * 100).round(2)
  end

  def self.to_csv
    attributes = %w[id user_id budget_project_id vote_weight created_at]
    
    CSV.generate(headers: true) do |csv|
      csv << ['Vote ID', 'Voter Name', 'Project Title', 'Vote Weight', 'Voted At']
      
      includes(:user, :budget_project).find_each do |vote|
        csv << [
          vote.id,
          vote.user.full_name,
          vote.budget_project.title,
          vote.vote_weight,
          vote.created_at
        ]
      end
    end
  end
end
