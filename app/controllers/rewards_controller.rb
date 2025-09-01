class RewardsController < ApplicationController
  before_action :authenticate_user!

  # { ids: [1,2,3] } を受け取り、表示済みとしてセッションから除去
  def ack_seen
    ids = Array(params[:ids]).map(&:to_i)
    session[:unseen_reward_ids] = Array(session[:unseen_reward_ids]) - ids
    # 互換同期
    session[:reward_boot_ids] = session[:unseen_reward_ids]
    head :no_content
  end
end