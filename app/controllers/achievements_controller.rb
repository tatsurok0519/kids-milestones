class AchievementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_child_and_milestone

  # POST /achievements/upsert
  def upsert
    state = (params[:state].presence || params[:toggle].presence).to_s
    ach   = @child.achievements.find_or_initialize_by(milestone_id: @milestone.id)
    authorize(ach, :upsert?)

    case state
    when "working"
      if ach.working?
        ach.assign_attributes(working: false)
      else
        ach.assign_attributes(working: true, achieved: false, achieved_at: nil)
      end
    when "achieved"
      if ach.achieved?
        ach.assign_attributes(working: false, achieved: false, achieved_at: nil)
      else
        ach.assign_attributes(working: false, achieved: true)
        ach.achieved_at ||= Time.current
      end
    else
      return render_card_html(status: :unprocessable_entity)
    end

    ach.save!

    # ごほうび（必要ならセッション積み）
    @new_rewards = RewardUnlocker.call(@child)
    if @new_rewards.present?
      ids = @new_rewards.map(&:id)
      session[:unseen_reward_ids] = (Array(session[:unseen_reward_ids]) + ids).uniq
    end

    # ★★ ここがポイント：常にフレームHTMLを返す（Streamは使わない）
    return render_card_html(status: :ok)

  rescue ActiveRecord::RecordNotFound
    render_card_html(status: :not_found)
  rescue Pundit::NotAuthorizedError
    render_card_html(status: :forbidden)
  rescue ActiveRecord::RecordInvalid
    render_card_html(status: :unprocessable_entity)
  end

  private

  def set_child_and_milestone
    @child = params[:child_id].present? ? Child.find(params[:child_id]) : current_child
    raise Pundit::NotAuthorizedError, "invalid child" unless @child
    authorize @child, :use?

    @milestone = Milestone.find(params.require(:milestone_id))
  end

  def latest_achievement
    policy_scope(Achievement).find_by(child_id: @child.id, milestone_id: @milestone.id)
  end

  # 期待されているフレームID（_card 側と完全一致）
  def card_frame_id
    "card_#{view_context.dom_id(@milestone)}" # => "card_milestone_13"
  end

  # ★ 常にフレームHTML（tasks/_card）を返す
  def render_card_html(status:)
    # デバッグ：実際にブラウザが期待しているIDをログに出す
    Rails.logger.info("[ach-upsert] Turbo-Frame header=#{request.headers['Turbo-Frame']} expected=#{card_frame_id}")

    # tasks/_card の先頭で <%= turbo_frame_tag "card_#{dom_id(milestone)}" %> を含むこと
    render partial: "tasks/card",
           locals:  { milestone: @milestone, achievement: latest_achievement },
           layout:  false,
           status:  status
  end
end