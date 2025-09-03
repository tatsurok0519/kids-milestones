class AccountsController < ApplicationController
  before_action :authenticate_user!
  before_action -> {
    add_crumb("メイン", dashboard_path)
    add_crumb("マイページ", account_path)
  }

  def show
    @user = current_user
    @children = current_user.children.order(:created_at)  # ← 追加
  end
end