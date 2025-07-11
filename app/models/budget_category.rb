class BudgetCategory < ApplicationRecord
  belongs_to :budget
  
  # Associations
  has_many :budget_projects, dependent: :destroy
  has_many :votes, through: :budget_projects

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :description, presence: true, length: { minimum: 5, maximum: 500 }
  validates :spending_limit_percentage, presence: true, 
            numericality: { 
              greater_than: 0, 
              less_than_or_equal_to: 100,
              message: "must be between 0 and 100"
            }
  validates :name, uniqueness: { scope: :budget_id, message: "must be unique within the budget" }

  # Scopes
  scope :with_projects, -> { joins(:budget_projects) }
  scope :over_limit, -> { 
    joins(:budget_projects, :budget)
      .group('budget_categories.id')
      .having('SUM(budget_projects.amount) > (budgets.total_amount * budget_categories.spending_limit_percentage / 100)')
  }

  # Instance methods
  def spending_limit_amount
    (budget.total_amount * spending_limit_percentage / 100).round(2)
  end

  def total_allocated_amount
    budget_projects.where(status: 'approved').sum(:amount) || 0
  end

  def total_proposed_amount
    budget_projects.where(status: ['pending', 'approved']).sum(:amount) || 0
  end

  def remaining_budget
    spending_limit_amount - total_allocated_amount
  end

  def utilization_percentage
    return 0 if spending_limit_amount <= 0
    (total_allocated_amount / spending_limit_amount * 100).round(2)
  end

  def over_limit?
    total_allocated_amount > spending_limit_amount
  end

  def near_limit?(threshold = 80)
    utilization_percentage >= threshold
  end

  def can_accommodate?(project_amount)
    (total_allocated_amount + project_amount) <= spending_limit_amount
  end

  def provisionally_funded_projects_amount
    project_ids = budget_projects
      .where(status: 'pending')
      .joins(:votes)
      .group('budget_projects.id')
      .having('SUM(votes.vote_weight) > 0')
      .pluck(:id)
    BudgetProject.where(id: project_ids).sum(:amount)
  end

  def projects_by_status
    {
      pending: budget_projects.where(status: 'pending').count,
      approved: budget_projects.where(status: 'approved').count,
      rejected: budget_projects.where(status: 'rejected').count
    }
  end

  def top_voted_projects(limit = 5)
    budget_projects
      .joins(:votes)
      .group('budget_projects.id')
      .order('COUNT(votes.id) DESC')
      .limit(limit)
  end

  def average_project_amount
    return 0 if budget_projects.empty?
    (budget_projects.sum(:amount) / budget_projects.count).round(2)
  end

  def status_color
    case utilization_percentage
    when 0...75
      'success'
    when 75...90
      'warning'
    else
      'danger'
    end
  end
end
