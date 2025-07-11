require 'csv'

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_many :budgets, dependent: :destroy
  has_many :budget_projects, dependent: :destroy
  has_many :votes, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :role, inclusion: { in: %w[admin participant] }

  # Enums
  enum role: {
    participant: 'participant',
    admin: 'admin'
  }

  # Scopes
  scope :participants, -> { where(role: 'participant') }
  scope :admins, -> { where(role: 'admin') }

  # Instance methods
  def full_name
    name.present? ? name : email.split('@').first.humanize
  end

  def display_name
    full_name
  end

  def can_vote_on?(project)
    project.votable? && !has_voted_for?(project)
  end

  def has_voted_for?(project)
    votes.exists?(budget_project_id: project.id)
  end

  def voted_projects_in_budget(budget)
    votes.joins(budget_project: { budget_category: :budget })
         .where(budgets: { id: budget.id })
         .includes(:budget_project)
  end

  def voting_stats_for_budget(budget)
    budget_votes = voted_projects_in_budget(budget)
    
    {
      total_votes: budget_votes.count,
      positive_votes: budget_votes.where('vote_weight > 0').count,
      negative_votes: budget_votes.where('vote_weight < 0').count,
      average_weight: budget_votes.average(:vote_weight)&.round(2) || 0
    }
  end

  def can_create_projects?
    participant? || admin?
  end

  def can_edit_project?(project)
    admin? || project.user == self
  end

  def participation_level
    total_votes = votes.count
    case total_votes
    when 0
      'New Member'
    when 1..5
      'Casual Participant'
    when 6..15
      'Active Participant'
    when 16..30
      'Engaged Citizen'
    else
      'Community Champion'
    end
  end

  def recent_activity(limit = 10)
    # Get recent votes and projects
    recent_votes = votes.includes(:budget_project).recent.limit(limit)
    recent_projects = budget_projects.recent.limit(limit)
    
    # Combine and sort by created_at
    (recent_votes.to_a + recent_projects.to_a)
      .sort_by(&:created_at)
      .reverse
      .first(limit)
  end

  def total_vote_weight
    votes.sum(:vote_weight) || 0
  end

  def favorite_categories
    # Find categories user votes on most
    votes.joins(budget_project: :budget_category)
         .group('budget_categories.name')
         .order('COUNT(*) DESC')
         .limit(3)
         .pluck('budget_categories.name')
  end

  def self.to_csv
    attributes = %w[id name email role created_at]
    
    CSV.generate(headers: true) do |csv|
      csv << attributes.map(&:humanize)
      
      all.each do |user|
        csv << user.attributes.values_at(*attributes)
      end
    end
  end
end
