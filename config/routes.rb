Rails.application.routes.draw do
  devise_for :users

  # 子ども選択はログイン時のみ許可にするのが安全（公開で必要なら外してください）
  authenticate :user do
    resources :children, only: [:index, :new, :create, :edit, :update, :destroy] do
      post :select, on: :member
    end
  end

  # ログイン後のダッシュボード
  get "/dashboard", to: "dashboard#show", as: :dashboard

  # 公開ページ（ログイン不要）
  get "/tasks",          to: "tasks#index"
  get "/chat",           to: "pages#chat"
  get "/report",         to: "pages#report"
  get "/home",           to: "home#index", as: :home
  get "/growth_policy",  to: "pages#growth_policy", as: :growth_policy
  get "mypage", to: "dashboard#show", as: :mypage

  # 健康チェック
  get "up" => "rails/health#show", as: :rails_health_check

  # 成績（アップサート）は1本に統一（↓どちらか一方でOK。ここでは明示ルート）
  post "achievements/upsert", to: "achievements#upsert", as: :achievements_upsert
  # ※もし resources 形式にしたいなら次の1行に置き換え、上の行は削除:
  # resources :achievements, only: [] { post :upsert, on: :collection }

  # 相談（SSE）
  resource :consult, only: [:show] do
    get :stream, on: :collection
  end
  get "consult",         to: "consults#show"
  get "consult/stream",  to: "consults#stream"

  # ログイン後のトップ
  authenticated :user do
    root to: "dashboard#show", as: :authenticated_root
  end

  # 未ログイン（公開）トップ
  unauthenticated do
    root to: "pages#landing", as: :unauthenticated_root
  end

  # 参考：必要ならアカウントページ
  resource :account, only: [:show]
end