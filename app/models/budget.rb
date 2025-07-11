require 'csv'

class Budget < ApplicationRecord
  belongs_to :user

  # Associations
  has_many :budget_categories, dependent: :destroy
  accepts_nested_attributes_for :budget_categories, allow_destroy: true
  has_many :budget_projects, through: :budget_categories
  has_many :budget_phases, dependent: :destroy
  has_many :votes, through: :budget_projects

  # Validations
  validates :title, presence: true, length: { minimum: 3, maximum: 200 }
  validates :description, presence: true, length: { minimum: 10, maximum: 2000 }
  validates :total_amount, presence: true, numericality: { greater_than: 0, less_than: 1_000_000_000 }
  validates :start_date, :end_date, presence: true
  validates :status, inclusion: { in: %w[draft active voting_closed completed archived] }
  validate :end_date_after_start_date
  validate :total_amount_covers_category_limits

  # Enums
  enum status: {
    draft: 'draft',
    active: 'active',
    voting_closed: 'voting_closed',
    completed: 'completed',
    archived: 'archived'
  }

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :current, -> { where('start_date <= ? AND end_date >= ?', Date.current, Date.current) }
  scope :upcoming, -> { where('start_date > ?', Date.current) }
  scope :past, -> { where('end_date < ?', Date.current) }

  # Instance methods
  def current_phase
    budget_phases.where('start_date <= ? AND end_date >= ?', Date.current, Date.current).first
  end

  def next_phase
    budget_phases.where('start_date > ?', Date.current).order(:start_date).first
  end

  def progress_percentage
    return 0 unless start_date && end_date
    
    total_days = (end_date - start_date).to_i
    return 100 if total_days <= 0
    
    elapsed_days = [(Date.current - start_date).to_i, 0].max
    [(elapsed_days.to_f / total_days * 100).round(2), 100].min
  end

  def total_allocated_amount
    budget_projects.where(status: 'approved').sum(:amount) || 0
  end

  def remaining_amount
    total_amount - total_allocated_amount
  end

  def total_votes_count
    votes.count
  end

  def category_utilization
    budget_categories.includes(:budget_projects).map do |category|
      used_amount = category.budget_projects.where(status: 'approved').sum(:amount) || 0
      limit_amount = (total_amount * (category.spending_limit_percentage || 0) / 100)
      
      {
        category: category,
        used_amount: used_amount,
        limit_amount: limit_amount,
        utilization_percentage: limit_amount > 0 ? (used_amount / limit_amount * 100).round(2) : 0
      }
    end
  end

  def can_accept_project?(project_amount, category)
    return false unless category.budget == self
    
    category_limit = total_amount * (category.spending_limit_percentage || 0) / 100
    current_category_total = category.budget_projects.where(status: 'approved').sum(:amount) || 0
    
    (current_category_total + project_amount) <= category_limit
  end

  def phase_transition_eligible?
    current_phase&.can_transition?
  end

  def auto_transition_to_next_phase!
    return false unless phase_transition_eligible?
    
    current_phase.update!(status: 'completed')
    next_phase&.update!(status: 'active')
  end

  private

  def end_date_after_start_date
    return unless start_date && end_date
    
    if end_date <= start_date
      errors.add(:end_date, "must be after start date")
    end
  end

  def total_amount_covers_category_limits
    return unless total_amount && budget_categories.exists?
    
    total_percentage = budget_categories.sum(:spending_limit_percentage) || 0
    if total_percentage > 100
      errors.add(:base, "Total spending limit percentages cannot exceed 100%")
    end
  end

  def self.to_csv
    headers = ['Budget Title', 'Category Name', 'Spending Limit (%)', 'Spending Limit (Amount)', 'Allocated Amount', 'Utilization (%)']
    
    CSV.generate(headers: true) do |csv|
      csv << headers
      
      includes(:budget_categories, :budget_projects).find_each do |budget|
        budget.category_utilization.each do |utilization_data|
          category = utilization_data[:category]
          csv << [
            budget.title,
            category.name,
            category.spending_limit_percentage,
            utilization_data[:limit_amount],
            utilization_data[:used_amount],
            utilization_data[:utilization_percentage]
          ]
        end
      end
    end
  end
end
