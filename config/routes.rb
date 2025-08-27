Rails.application.routes.draw do
  devise_for :users

  # ログイン時のトップ（ダッシュボード）
  authenticate :user do
    root "dashboard#show", as: :authenticated_root
  end

  # 未ログイン時のトップ（できるかな公開ページ）
  unauthenticated do
    root "tasks#index", as: :unauthenticated_root
  end

  resources :children

  get "/tasks",  to: "tasks#index"
  get "/chat",   to: "pages#chat"
  get "/report", to: "pages#report"

  get "up" => "rails/health#show", as: :rails_health_check
end