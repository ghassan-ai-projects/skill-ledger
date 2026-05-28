Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :skills, only: %i[index show create]

      post "skills/:skill_id/execute", to: "executions#create", as: :execute_skill

      resources :executions, only: %i[index]
      resources :ledger, only: %i[index], controller: "ledger_entries"
    end
  end
end
