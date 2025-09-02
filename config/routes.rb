Rails.application.routes.draw do
  devise_for :users

  authenticate :user do
    # 子ども管理はログイン必須に
    resources :children do               # ← new/index/show/edit などが復活
      resource :report, only: :show, controller: "reports"
    end
  end

  # ログイン後のダッシュボード
  get "/dashboard", to: "dashboard#show", as: :dashboard
  get "mypage",     to: "dashboard#show", as: :mypage

  # 公開ページ（ログイン不要）
  get "/tasks",         to: "tasks#index"
  get "/chat",          to: "pages#chat"
  get "/report",        to: "pages#report"         # ←静的説明ページなら残してOK（helper: report_path）
  get "/home",          to: "home#index",          as: :home
  get "/growth_policy", to: "pages#growth_policy", as: :growth_policy

  # 健康チェック
  get "up" => "rails/health#show", as: :rails_health_check

  # 成績（アップサート）
  post "achievements/upsert", to: "achievements#upsert", as: :achievements_upsert

  # ごほうび既読
  post "rewards/ack", to: "rewards#ack_seen", as: :ack_rewards

  # 相談（SSE）
  resource :consult, only: [:show] do
    get :stream, on: :collection
  end
  # ↑上で定義しているので下の重複は削除
  # get "consult",         to: "consults#show"
  # get "consult/stream",  to: "consults#stream"

  # ログイン後のトップ
  authenticated :user do
    root to: "dashboard#show", as: :authenticated_root
  end

  # 未ログイン（公開）トップ
  unauthenticated do
    root to: "pages#landing", as: :unauthenticated_root
  end

  # エラーページ
  %w[404 403 422 500].each do |code|
    match code, to: "errors#show", via: :all, code: code
  end

  # 参考：必要ならアカウントページ
  resource :account, only: [:show]
end