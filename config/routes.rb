Rails.application.routes.draw do
  # ルートをホームに
  root "home#index"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
