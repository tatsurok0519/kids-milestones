Rails.application.routes.draw do
  devise_for :users

  resources :children, only: [] do
    post :select, on: :member
  end
  
  # ログイン後のダッシュボード
  get "/dashboard", to: "dashboard#show", as: :dashboard

  # 公開ページ（ログイン不要）
  get "/tasks",  to: "tasks#index"
  get "/chat",   to: "pages#chat"
  get "/report", to: "pages#report"
  get "/home",   to: "home#index", as: :home
  get "/growth_policy", to: "pages#growth_policy", as: :growth_policy

  get "up" => "rails/health#show", as: :rails_health_check
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

  # ✅ マイページ（表示のみ）
  resource :account, only: [:show]

  resources :achievements, only: [] do
    post :upsert, on: :collection
  end
  
  post "achievements/upsert", to: "achievements#upsert", as: :achievements_upsert

  # 末尾など適所に追記
  resource :consult, only: [:show] do
    get :stream, on: :collection   # ← ストリーミング（SSE）
  end

end