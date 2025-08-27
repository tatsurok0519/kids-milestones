class PagesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def chat
    # ビューが無くてもOKにする
    render plain: "OK"
  end

  def report
    render plain: "OK"
  end
end