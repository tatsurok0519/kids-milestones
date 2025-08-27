Rails.application.routes.draw do
  get 'children/index'
  get 'children/new'
  get 'children/edit'
  get 'children/show'
  devise_for :users, controllers: { registrations: "users/registrations" }

  # 体験導線（未ログインOK）
  get "/tasks",  to: "tasks#index"
  get "/chat",   to: "pages#chat"
  get "/report", to: "pages#report"

  # こどもプロフィール
  resources :children

  authenticated :user do
    root to: "dashboard#show", as: :authenticated_root
    get "/dashboard", to: "dashboard#show", as: :dashboard
  end

  unauthenticated do
    root to: "tasks#index", as: :unauthenticated_root
  end

  get "up" => "rails/health#show", as: :rails_health_check
end