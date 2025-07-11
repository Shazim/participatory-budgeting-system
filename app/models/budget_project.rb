require "csv"

class BudgetProject < ApplicationRecord
  belongs_to :budget_category
  belongs_to :user
  has_many :votes, dependent: :destroy
  has_one :impact_metric, dependent: :destroy
  accepts_nested_attributes_for :impact_metric, allow_destroy: true

  delegate :budget, to: :budget_category, allow_nil: true

  validates :title, presence: true, length: { minimum: 5, maximum: 200 }
  validates :description, presence: true, length: { minimum: 20, maximum: 2000 }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[draft pending approved rejected implemented] }

  # Enums
  enum status: {
    draft: "draft",
    pending: "pending",
    approved: "approved",
    rejected: "rejected",
    implemented: "implemented"
  }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :approved_or_implemented, -> { where(status: [ "approved", "implemented" ]) }
  scope :votable, -> { where(status: [ "pending", "approved" ]) }
  scope :by_category, ->(category_id) { where(budget_category_id: category_id) }
  scope :search_by_term, ->(query) {
    where('budget_projects.title ILIKE :q OR budget_projects.description ILIKE :q', q: "%#{query}%")
  }
  scope :with_impact_data, -> { joins(:impact_metric) }
  scope :min_beneficiaries, ->(count) { with_impact_data.where("impact_metrics.estimated_beneficiaries >= ?", count) }
  scope :max_timeline, ->(months) { with_impact_data.where("impact_metrics.timeline_months <= ?", months) }
  scope :min_sustainability, ->(score) { with_impact_data.where("impact_metrics.sustainability_score >= ?", score) }

  scope :within_budget, ->(amount) { where("amount <= ?", amount) }
  scope :popular, -> {
    left_joins(:votes)
      .group("budget_projects.id")
      .order(Arel.sql("COUNT(votes.id) DESC"))
      .select("budget_projects.*")
  }

  # Instance methods
  def vote_count
    votes.count
  end

  def positive_votes_count
    votes.positive.count
  end

  def negative_votes_count
    votes.negative.count
  end

  def total_vote_weight
    votes.sum(:vote_weight) || 0
  end

  def average_vote_weight
    return 0 if votes.count == 0
    (total_vote_weight.to_f / votes.count).round(2)
  end

  def votable?
    pending? || approved?
  end

  def can_be_voted_on?
    votable? && budget.active?
  end

  def is_within_budget?
    budget_category.remaining_budget >= amount
  end

  def utilization_percentage
    return 0 if budget_category.spending_limit == 0
    ((amount.to_f / budget_category.spending_limit) * 100).round(2)
  end

  def submission_allowed?
    current_phase = budget_category.budget.current_phase
    current_phase&.allows_submissions?
  end

  def voting_allowed?
    current_phase = budget_category.budget.current_phase
    current_phase&.allows_voting?
  end

  def status_badge_class
    case status
    when "draft"
      "secondary"
    when "pending"
      "primary"
    when "approved"
      "success"
    when "rejected"
      "danger"
    when "implemented"
      "info"
    else
      "secondary"
    end
  end

  def short_description(length = 100)
    description.length > length ? "#{description[0...length]}..." : description
  end

  def display_title
    title.titleize
  end

  def impact_summary
    return "No impact assessment" unless impact_metric

    "Benefits #{impact_metric.estimated_beneficiaries} people"
  end

  def self.to_csv
    attributes = %w[id title description amount status created_at]
    CSV.generate(headers: true) do |csv|
      csv << attributes
      all.each do |project|
        csv << project.attributes.values_at(*attributes)
      end
    end
  end

  def self.to_csv_with_impact
    CSV.generate(headers: true) do |csv|
      csv << [
        "Project ID", "Project Title", "Status", "Amount",
        "Estimated Beneficiaries", "Timeline (Months)", "Sustainability Score",
        "Environmental Impact", "Social Impact", "Economic Impact"
      ]

      includes(:impact_metric).find_each do |project|
        csv << [
          project.id,
          project.title,
          project.status,
          project.amount,
          project.impact_metric&.estimated_beneficiaries,
          project.impact_metric&.timeline_months,
          project.impact_metric&.sustainability_score,
          project.impact_metric&.environmental_impact,
          project.impact_metric&.social_impact,
          project.impact_metric&.economic_impact
        ]
      end
    end
  end
end
