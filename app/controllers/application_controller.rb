class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?

  helper_method :current_budget, :active_budgets, :user_can_vote?, :format_currency

  def current_budget
    @current_budget ||= begin
      if params[:budget_id]
        Budget.find(params[:budget_id])
      elsif session[:current_budget_id]
        Budget.find_by(id: session[:current_budget_id])
      end
    end
  end

  def user_can_vote?(budget_project)
    return false unless current_user
    current_user.can_vote_on?(budget_project)
  end

  def format_currency(value)
    view_context.number_to_currency(value, precision: 0)
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :role ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :role ])
  end

  def ensure_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "You are not authorized to perform this action."
    end
  end
end
