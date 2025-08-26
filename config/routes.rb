# config/routes.rb
Rails.application.routes.draw do
  get 'tasks/index'
  devise_for :users
  devise_for :users, controllers: { registrations: "users/registrations" }

  authenticated :user do
    root "dashboard#show", as: :authenticated_root
    get "/dashboard", to: "dashboard#show", as: :dashboard
  end

  # 未ログインはまず「できるかな」を見せる
  unauthenticated do
    root "tasks#index", as: :unauthenticated_root
  end

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  get "/tasks",  to: "tasks#index"   # だれでもOK
  get "/chat",   to: "pages#chat"    # だれでもOK
  get "/report", to: "pages#report"  # 将来: 要ログインに戻す

  get "up" => "rails/health#show", as: :rails_health_check
end