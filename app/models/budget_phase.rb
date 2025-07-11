class BudgetPhase < ApplicationRecord
  belongs_to :budget
  has_many :votes, dependent: :destroy

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :phase_type, inclusion: { in: %w[submission review voting implementation evaluation] }
  validates :status, inclusion: { in: %w[pending active completed cancelled] }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date
  validate :no_date_overlap_with_other_phases

  # Enums
  enum status: {
    pending: "pending",
    active: "active",
    completed: "completed",
    cancelled: "cancelled"
  }

  enum phase_type: {
    submission: "submission",
    review: "review",
    voting: "voting",
    implementation: "implementation",
    evaluation: "evaluation"
  }

  # Scopes
  scope :chronological, -> { order(:start_date) }
  scope :current, -> { where("start_date <= ? AND end_date >= ?", Date.current, Date.current) }
  scope :upcoming, -> { where("start_date > ?", Date.current) }
  scope :past, -> { where("end_date < ?", Date.current) }

  # Instance methods
  def allows_submissions?
    submission? && active?
  end

  def allows_voting?
    voting? && active?
  end

  def allows_project_submission?
    allows_submissions?
  end

  def current?
    Date.current.between?(start_date, end_date) && active?
  end

  def upcoming?
    start_date > Date.current
  end

  def past?
    end_date < Date.current
  end

  def phase_icon
    case phase_type
    when "submission"
      "file-alt"
    when "review"
      "search"
    when "voting"
      "vote-yea"
    when "implementation"
      "cogs"
    when "evaluation"
      "check-double"
    else
      "question-circle"
    end
  end

  def phase_color
    case phase_type
    when "submission"
      "primary"
    when "review"
      "info"
    when "voting"
      "success"
    when "implementation"
      "warning"
    when "evaluation"
      "secondary"
    else
      "muted"
    end
  end

  def duration_days
    (end_date - start_date).to_i + 1
  end

  def days_remaining
    return 0 if past?
    return duration_days if upcoming?
    (end_date - Date.current).to_i + 1
  end

  def progress_percentage
    return 100 if past?
    return 0 if upcoming?

    total_days = duration_days
    elapsed_days = (Date.current - start_date).to_i + 1
    ((elapsed_days.to_f / total_days) * 100).round(2)
  end

  def status_display
    case status
    when "pending"
      "Not Started"
    when "active"
      "In Progress"
    when "completed"
      "Completed"
    when "cancelled"
      "Cancelled"
    else
      status.titleize
    end
  end

  def phase_type_display
    case phase_type
    when "submission"
      "Project Submission"
    when "review"
      "Project Review"
    when "voting"
      "Community Voting"
    when "implementation"
      "Implementation"
    when "evaluation"
      "Evaluation"
    else
      phase_type.titleize
    end
  end

  def vote_count
    votes.count
  end

  def participant_count
    votes.joins(:user).distinct.count(:user_id)
  end

  def can_transition_to_active?
    pending? && start_date <= Date.current
  end

  def can_transition_to_completed?
    active? && end_date < Date.current
  end

  def activate!
    return false unless can_transition_to_active?

    # Deactivate other active phases in the same budget
    budget.budget_phases.active.where.not(id: id).update_all(status: "completed")

    update!(status: "active")
  end

  def complete!
    return false unless can_transition_to_completed?
    update!(status: "completed")
  end

  def cancel!
    return false if completed?
    update!(status: "cancelled")
  end

  private

  def end_date_after_start_date
    return unless start_date && end_date

    if end_date < start_date
      errors.add(:end_date, "must be after start date")
    end
  end

  def no_date_overlap_with_other_phases
    return unless start_date && end_date && budget_id

    overlapping_phases = budget.budget_phases
                               .where.not(id: id)
                               .where(
                                 "(start_date <= ? AND end_date >= ?) OR (start_date <= ? AND end_date >= ?) OR (start_date >= ? AND end_date <= ?)",
                                 start_date, start_date,
                                 end_date, end_date,
                                 start_date, end_date
                               )

    if overlapping_phases.exists?
      errors.add(:base, "Phase dates cannot overlap with existing phases")
    end
  end
end
