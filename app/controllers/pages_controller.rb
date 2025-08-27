class PagesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  # ← このアクションはテンプレートを描画させるので、何も書かない
  def landing; end

  # 既存ならそのままでOK（不要なら削っても良い）
  def chat;  end
  def report; end
end