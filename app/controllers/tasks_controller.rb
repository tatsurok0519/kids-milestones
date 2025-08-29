class TasksController < ApplicationController
  def index
    # --- 年齢帯: "0".."5" or "all" or nil ---
    band_param = params[:age_band].presence
    if band_param == "all"
      @age_band_label = "全年齢"
      scope = Milestone.all
    else
      @age_band_index =
        if band_param.present?
          band_param.to_i.clamp(0, 5)
        elsif current_child
          current_child.age_band_index
        else
          0
        end
      @age_band_label = "#{@age_band_index}–#{@age_band_index + 1}歳"
      scope = Milestone.for_age_band(@age_band_index)
    end

    @categories      = Milestone.distinct.order(:category).pluck(:category).compact
    @difficulties    = [1, 2, 3]
    @only_unachieved = params[:only_unachieved] == "1"

    scope = scope.by_category(params[:category])
                 .by_difficulty(params[:difficulty])

    scope = scope.unachieved_for(current_child) if user_signed_in? && current_child && @only_unachieved

    # --- ページング（並びは難易度→IDの安定順） ---
    @milestones = scope.order(:difficulty, :id).page(params[:page]).per(20)

    # ログイン時は表示中タスクの達成状況を一括取得
    if user_signed_in? && current_child
      achs = Achievement.where(child: current_child, milestone_id: @milestones.select(:id))
      @ach_by_ms = achs.index_by(&:milestone_id)
    end
    @parent_tip = ParentTip.for(child: (user_signed_in? ? current_child : nil), date: Date.current)
  end
end