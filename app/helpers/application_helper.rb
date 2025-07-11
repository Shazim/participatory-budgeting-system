module ApplicationHelper
  include ActionView::Helpers::NumberHelper

  # Format currency amounts
  def format_currency(amount)
    number_to_currency(amount, precision: 0)
  end

  # Get color class for category utilization
  def category_utilization_class(percentage)
    case percentage
    when 0..60
      "success"
    when 61..80
      "warning"
    else
      "danger"
    end
  end

  # Get color class for phase status
  def phase_status_class(phase)
    case phase.status
    when "active"
      "success"
    when "completed"
      "info"
    when "pending"
      "warning"
    else
      "secondary"
    end
  end

  # Check if user can vote on a project
  def can_vote_on_project?(user, project)
    return false unless user
    return false unless project.budget_category.budget.active?

    current_phase = project.budget_category.budget.current_phase
    return false unless current_phase&.allows_voting?

    # Check if user already voted
    !user.votes.exists?(budget_project: project, budget_phase: current_phase)
  end

  # Check if user has voted for a project
  def has_voted_for_project?(user, project)
    return false unless user

    current_phase = project.budget_category.budget.current_phase
    return false unless current_phase

    user.votes.exists?(budget_project: project, budget_phase: current_phase)
  end

  # Get user's vote for a project
  def user_vote_for_project(user, project)
    return nil unless user

    current_phase = project.budget_category.budget.current_phase
    return nil unless current_phase

    user.votes.find_by(budget_project: project, budget_phase: current_phase)
  end

  # Format vote weight display
  def format_vote_weight(weight)
    case weight
    when 1..5
      "+" + weight.to_s
    when -5..-1
      weight.to_s
    else
      weight.to_s
    end
  end

  # Get impact category color
  def impact_category_color(category)
    case category.to_s
    when "very_positive"
      "success"
    when "positive"
      "primary"
    when "neutral"
      "secondary"
    when "negative"
      "warning"
    when "very_negative"
      "danger"
    else
      "secondary"
    end
  end

  # Generate avatar initials
  def avatar_initials(name)
    name.split.map(&:first).join.upcase[0, 2]
  end

  # Check if current user is admin
  def current_user_admin?
    current_user&.admin?
  end

  # Get bootstrap alert class for flash messages
  def flash_class(level)
    bootstrap_alert_class = {
      "success" => "alert-success",
      "error" => "alert-danger",
      "warning" => "alert-warning",
      "alert" => "alert-warning",
      "notice" => "alert-info"
    }
    bootstrap_alert_class[level] || bootstrap_alert_class["notice"]
  end

  # Format project status badge
  def project_status_badge(status)
    case status
    when "approved"
      content_tag :span, status.humanize, class: "badge bg-success"
    when "pending"
      content_tag :span, status.humanize, class: "badge bg-warning"
    when "rejected"
      content_tag :span, status.humanize, class: "badge bg-danger"
    else
      content_tag :span, status.humanize, class: "badge bg-secondary"
    end
  end

  # Format budget status badge
  def budget_status_badge(status)
    case status
    when "active"
      content_tag :span, status.humanize, class: "badge bg-success"
    when "draft"
      content_tag :span, status.humanize, class: "badge bg-warning"
    when "completed"
      content_tag :span, status.humanize, class: "badge bg-info"
    when "voting_closed"
      content_tag :span, "Voting Closed", class: "badge bg-secondary"
    else
      content_tag :span, status.humanize, class: "badge bg-secondary"
    end
  end

  # Calculate progress percentage
  def progress_percentage(current, total)
    return 0 if total.zero?
    ((current.to_f / total) * 100).round(1)
  end

  # Truncate text with proper handling
  def smart_truncate(text, length = 150)
    return "" if text.blank?

    if text.length <= length
      text
    else
      text.truncate(length, separator: " ")
    end
  end

  # Get user's full name or email
  def user_display_name(user)
    user.name.present? ? user.name : user.email.split("@").first.humanize
  end

  # Format date range
  def date_range(start_date, end_date)
    if start_date.year == end_date.year
      if start_date.month == end_date.month
        "#{start_date.strftime('%B %d')} - #{end_date.strftime('%d, %Y')}"
      else
        "#{start_date.strftime('%B %d')} - #{end_date.strftime('%B %d, %Y')}"
      end
    else
      "#{start_date.strftime('%B %d, %Y')} - #{end_date.strftime('%B %d, %Y')}"
    end
  end

  # Check if date is in the past
  def date_passed?(date)
    date < Date.current
  end

  # Check if date is today
  def date_today?(date)
    date == Date.current
  end

  # Get days remaining
  def days_remaining(end_date)
    return 0 if end_date < Date.current
    (end_date - Date.current).to_i
  end

  # Format time ago with fallback
  def time_ago_with_fallback(time)
    return "Never" if time.blank?
    time_ago_in_words(time)
  end

  # Check if user can edit resource
  def can_edit_resource?(resource, user = current_user)
    return false unless user
    return true if user.admin?

    # Users can edit their own resources
    resource.respond_to?(:user) && resource.user == user
  end

  # Get voting phase for budget
  def voting_phase_for_budget(budget)
    budget.budget_phases.where(phase_type: "voting").active.first
  end

  # Check if voting is open for budget
  def voting_open_for_budget?(budget)
    current_phase = budget.current_phase
    current_phase&.allows_voting?
  end
end
