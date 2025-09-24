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
      return respond_invalid_state
    end

    ach.save!

    # ごほうび判定
    @new_rewards = RewardUnlocker.call(@child)
    if @new_rewards.present?
      ids = @new_rewards.map(&:id)
      session[:unseen_reward_ids] = (Array(session[:unseen_reward_ids]) + ids).uniq
    end

    respond_ok
  rescue ActiveRecord::RecordNotFound
    head :not_found
  rescue Pundit::NotAuthorizedError
    head :forbidden
  rescue ActiveRecord::RecordInvalid
    respond_ng
  end

  private

  # ===== helpers =============================================================

  def set_child_and_milestone
    @child = params[:child_id].present? ? Child.find(params[:child_id]) : current_child
    raise Pundit::NotAuthorizedError, "invalid child" unless @child
    authorize @child, :use?

    @milestone = Milestone.find(params.require(:milestone_id))
  end

  def latest_achievement
    policy_scope(Achievement).find_by(child_id: @child.id, milestone_id: @milestone.id)
  end

  # ★ カードのフレームIDをここで一元管理（カード側と必ず一致させる）
  def card_frame_id
    "card_#{view_context.dom_id(@milestone)}"  # => 例: "card_milestone_24"
  end

  # Frame要求ならフレームHTML、そうでなければTurbo Streamを返す
  def render_card(achievement:, status:)
    if turbo_frame_request?
      # tasks/_card は <%= turbo_frame_tag "card_#{dom_id(milestone)}" %> を含むこと
      render partial: "tasks/card",
             locals:  { milestone: @milestone, achievement: achievement },
             layout:  false,
             status:  status
    else
      streams = []

      # カード全体を置換（target は card_frame_id に統一）
      streams << turbo_stream.replace(
        card_frame_id,
        partial: "tasks/card",
        locals:  { milestone: @milestone, achievement: achievement }
      )

      if @new_rewards.present?
        streams << turbo_stream.append(
          "toasts",
          partial: "shared/reward_toast",
          locals:  { rewards: @new_rewards }
        )
        ids_csv = @new_rewards.map(&:id).join(",")
        marker  = view_context.tag.div(nil, data: { reward_unlocked: ids_csv })
        streams << turbo_stream.update("reward_animator", marker)
      end

      render turbo_stream: streams, status: status
    end
  end

  def respond_ok
    respond_to do |f|
      f.turbo_stream { render_card(achievement: latest_achievement, status: :ok) }
      f.html         { render_card(achievement: latest_achievement, status: :ok) }
      f.json do
        a = latest_achievement
        render json: {
          id: a&.id, child_id: @child.id, milestone_id: @milestone.id,
          working: a&.working, achieved: a&.achieved, achieved_at: a&.achieved_at
        }, status: :ok
      end
    end
  end

  def respond_ng
    respond_to do |f|
      f.turbo_stream { render_card(achievement: latest_achievement, status: :unprocessable_entity) }
      f.html         { render_card(achievement: latest_achievement, status: :unprocessable_entity) }
      f.json         { render json: { error: "unprocessable" }, status: :unprocessable_entity }
    end
  end

  def respond_invalid_state
    respond_to do |f|
      # Frame要求で head を返すと "Content missing" になるため、カードを返す
      f.turbo_stream { render_card(achievement: latest_achievement, status: :unprocessable_entity) }
      f.html         { render_card(achievement: latest_achievement, status: :unprocessable_entity) }
      f.json         { render json: { error: "invalid state" }, status: :unprocessable_entity }
    end
  end
end