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

    # ▼ フィルタ受け取り
    @category    = params[:category].presence
    @difficulty  = params[:difficulty].presence
    @unachieved  = params[:unachieved].to_s == "1"  # ← チェックボックス想定

    # ▼ 一覧の母集団を組み立て（順序は最後で付ける）
    scope = Milestone
              .for_age_band(@age_band_index)
              .by_category(@category)
              .by_difficulty(@difficulty)

    # ▼ 未達成フィルタ（ログイン＋子ども選択時のみ有効）
    if @unachieved && current_user && current_child
      scope = scope.unachieved_for(current_child)
    end

    # ▼ 並び順・ページング（Kaminari）
    #    ※ Kaminari 未導入なら: `bin/bundle add kaminari`
    @milestones  = scope.order(:difficulty, :id).page(params[:page]).per(24)
    @total_count = scope.count

    # ▼ プルダウン用
    @categories   = Milestone.distinct.order(:category).pluck(:category).compact
    @difficulties = (1..3).map { |i| ["#{'★' * i} (#{i})", i] }
    @age_band_label = "#{@age_band_index}–#{@age_band_index + 1}歳"

    # ▼ 表示中タスクの達成状況（ビューで右上バッジ/ボタン状態に使用）
    if current_user && current_child && @milestones.present?
      achs = current_child.achievements.where(milestone_id: @milestones.pluck(:id))
      @ach_by_ms = achs.index_by(&:milestone_id) # { milestone_id => Achievement }
    end

    # ▼ ページャのクエリ引き継ぎ用（ビューで: paginate @milestones, params: @pager_params）
    @pager_params = request.query_parameters.except(:page)
  end
end