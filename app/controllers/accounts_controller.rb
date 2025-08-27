class AccountsController < ApplicationController
  before_action :authenticate_user!

  def show
    # 画面表示用だけ。必要なら @children_count など出してもOK
  end
end