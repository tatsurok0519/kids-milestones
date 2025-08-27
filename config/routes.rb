Rails.application.routes.draw do
  devise_for :users

  resources :children do
    post :select, on: :member   # /children/:id/select にPOST
  end
  
  # ログイン後のダッシュボード
  get "/dashboard", to: "dashboard#show", as: :dashboard

  # 公開ページ（ログイン不要）
  get "/tasks",  to: "tasks#index"
  get "/chat",   to: "pages#chat"
  get "/report", to: "pages#report"
  get "/home",   to: "home#index", as: :home

  # ★ 子ども管理（ログイン必須）
  authenticate :user do
    resources :children, only: [:index, :new, :create, :edit, :update, :destroy]
  end

  # ログイン後のトップ
  authenticated :user do
    root to: "dashboard#show", as: :authenticated_root
  end

  # 未ログインのトップ（公開用）
  unauthenticated do
    root to: "pages#landing", as: :unauthenticated_root
  end

  get "up" => "rails/health#show", as: :rails_health_check
end