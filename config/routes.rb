# config/routes.rb
Rails.application.routes.draw do
  # Devise は1回だけ
  devise_for :users, controllers: { registrations: "users/registrations" }

  # 未ログインでも見せたいページ（体験導線）
  get "/tasks",  to: "tasks#index"
  get "/chat",   to: "pages#chat"
  get "/report", to: "pages#report"

  # ログイン後のルート
  authenticated :user do
    root to: "dashboard#show", as: :authenticated_root
    get "/dashboard", to: "dashboard#show", as: :dashboard
  end

  # 未ログイン時のルート（体験トップ）
  unauthenticated do
    root to: "tasks#index", as: :unauthenticated_root
  end

  # ヘルスチェック
  get "up" => "rails/health#show", as: :rails_health_check
end