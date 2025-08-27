class TasksController < ApplicationController
  # 認証なしで見せたい
  skip_before_action :authenticate_user!, only: [:index], raise: false

  def index
    # 1) パラメータがあればそれを優先
    if params[:age_band].present?
      @age_band_index = params[:age_band].to_i.clamp(0, 5)
    # 2) ログイン中は選択中の子の年齢帯
    elsif current_user && current_child
      @age_band_index = current_child.age_band_index
    # 3) 未ログイン時は 0–1歳を初期値
    else
      @age_band_index = 0
    end

    # ▼ 追加：カテゴリ／難易度の絞り込み
    @category   = params[:category].presence
    @difficulty = params[:difficulty].presence

    @milestones = Milestone
                    .for_age_band(@age_band_index)
                    .by_category(@category)
                    .by_difficulty(@difficulty)
                    .order(:difficulty, :id)

    # プルダウン用（ビューで使う想定。今は仕込みだけ）
    @categories   = Milestone.distinct.order(:category).pluck(:category).compact
    @difficulties = (1..3).map { |i| ["#{'★' * i} (#{i})", i] }

    @age_band_label = "#{@age_band_index}–#{@age_band_index + 1}歳"
  end
end