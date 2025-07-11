Rails.application.routes.draw do
  # Devise routes for authentication
  devise_for :users
  
  # Root route
  root 'home#index'
  
  # Home and dashboard routes
  get 'dashboard', to: 'home#dashboard'
  get 'home/index'
  get 'home/dashboard'

  # Main application routes
  resources :budgets do
    member do
      patch :activate
      patch :close_voting
      get :categories
    end
    
    resources :budget_categories, except: [:index] do
      member do
        get :utilization
      end
    end
    
    resources :budget_phases do
      member do
        patch :transition
        patch :activate
        patch :complete
      end
    end
  end

  resources :budget_projects do
    member do
      post :vote
      post :preview_vote
      patch :approve
      patch :reject
      get :voting_results
    end
    
    resources :impact_metrics, only: [:show, :edit, :update]
  end

  resources :votes, only: [:create, :update, :destroy, :edit] do
    collection do
      get :my_votes
    end
  end

  # Admin namespace
  namespace :admin do
    root 'dashboard#index'
    
    get 'dashboard/index', to: 'dashboard#index'
    get 'dashboard/analytics', to: 'dashboard#analytics'
    get 'dashboard/reports', to: 'dashboard#reports'
    get 'dashboard/category_monitoring', to: 'dashboard#category_monitoring'
    get 'dashboard/phase_analytics', to: 'dashboard#phase_analytics'
    
    resources :budget_categories, only: [:index, :edit, :update] do
      member do
        get :utilization_report
        patch :update_limits
      end
    end
    
    resources :budgets, only: [:index, :show, :edit, :update] do
      member do
        get :monitoring
        get :voting_analytics
        patch :force_transition
      end
    end
    
    resources :budget_projects, only: [:index, :show, :edit, :update] do
      member do
        patch :approve
        patch :reject
        get :impact_report
      end
    end
    
    resources :users, only: [:index, :show, :edit, :update] do
      member do
        patch :toggle_role
      end
    end
  end

  # API routes for AJAX requests
  namespace :api do
    namespace :v1 do
      resources :budget_categories, only: [] do
        member do
          get :utilization
        end
      end
      
      resources :budget_projects, only: [] do
        member do
          get :voting_stats
        end
      end
      
      resources :votes, only: [:create, :update, :destroy]
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
