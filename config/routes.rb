Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :skills, only: %i[index show create] do
        member do
          get :reviews, to: "reviews#index"
        end
      end

      post "skills/:skill_id/execute", to: "executions#create", as: :execute_skill

      resources :executions, only: %i[index] do
        member do
          patch :fail
          post :review, to: "reviews#create"
        end
      end

      resources :ledger, only: %i[index], controller: "ledger_entries"

      get "reports", to: "reports#index"

      resources :authors, only: [] do
        member do
          get :analytics, to: "analytics#show"
          get :earnings, to: "analytics#earnings"
        end
      end

      resources :favorites, only: %i[create index destroy]

      get "me/library", to: "library#index"
    end
  end
end
