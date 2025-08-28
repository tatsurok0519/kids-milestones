class AccountsController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @children = current_user.children.order(:created_at)  # ← 追加
  end
end