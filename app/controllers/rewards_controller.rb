class RewardsController < ApplicationController
  before_action :authenticate_user!

  # POST /rewards/ack
  #
  # 既読化の仕様：
  # - params[:ids] が配列 or "1,2,3" のとき → そのIDだけ既読（部分既読）
  # - params[:ids] が無い or "all" のとき → すべて既読（全消去）
  #
  # レスポンス：
  # - JSON: { unseen_reward_ids: [...] } を返す（UI側で残件確認に使える）
  # - Turbo/HTML: 204 No Content（ボディ無し）
  def ack_seen
    current = Array(session[:unseen_reward_ids]).map(&:to_i).uniq
    ack_ids = normalize_ids(params[:ids])

    remaining =
      if ack_ids == :all
        []
      else
        current - ack_ids
      end

    # セッション更新（互換の reward_boot_ids も同期）
    session[:unseen_reward_ids] = remaining
    session[:reward_boot_ids]   = remaining

    respond_to do |format|
      format.json        { render json: { unseen_reward_ids: remaining }, status: :ok }
      format.turbo_stream
      format.html
    end
    head :no_content unless performed?
  end

  private

  # ids を正規化：
  # - nil / "" / "all" → :all
  # - ["1","2"] / "1,2,3" → [1,2,3]
  def normalize_ids(value)
    return :all if value.blank? || value.to_s.strip.downcase == "all"

    list =
      case value
      when Array  then value
      else             value.to_s.split(",")
      end

    list.map(&:to_i).reject(&:zero?).uniq
  end
end