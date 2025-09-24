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

    # ごほうびの解放判定
    @new_rewards = RewardUnlocker.call(@child)

    Rails.logger.info(
      "[ach-upsert] child=#{@child.id} achieved_count=#{@child.achievements.where(achieved: true).count} " \
      "new_reward_ids=#{Array(@new_rewards).map(&:id)}"
    )

    if @new_rewards.present?
      ids = @new_rewards.map(&:id)
      session[:unseen_reward_ids] = (Array(session[:unseen_reward_ids]) + ids).uniq
    end

    respond_ok

  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("[achievements#upsert] 404 child or milestone not found")
    head :not_found
  rescue Pundit::NotAuthorizedError
    Rails.logger.warn("[achievements#upsert] 403 not authorized")
    head :forbidden
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn("[achievements#upsert] 422 #{e.record.errors.full_messages.join(', ')}")
    respond_ng
  end

  private

  def set_child_and_milestone
    @child =
      if params[:child_id].present?
        Child.find(params[:child_id])
      else
        current_child
      end
    raise Pundit::NotAuthorizedError, "invalid child" unless @child
    authorize @child, :use?

    @milestone = Milestone.find(params.require(:milestone_id))
  end

  def latest_achievement
    policy_scope(Achievement).find_by(child_id: @child.id, milestone_id: @milestone.id)
  end

  # Turbo Stream：カード全体を置換し、演出も積む
  def render_controls(achievement:, status:)
    streams = []

    # 1) ★ カード全体を置換（target は :card）
    streams << turbo_stream.replace(
      view_context.dom_id(@milestone, :card),
      partial: "tasks/card",
      locals:  { milestone: @milestone, achievement: achievement }
    )

    if @new_rewards.present?
      # 2) トースト
      streams << turbo_stream.append(
        "toasts",
        partial: "shared/reward_toast",
        locals:  { rewards: @new_rewards }
      )

      # 3) 演出用マーカー
      ids_csv = @new_rewards.map(&:id).join(",")
      marker  = view_context.tag.div(nil, data: { reward_unlocked: ids_csv })
      streams << turbo_stream.update("reward_animator", marker)
    end

    render turbo_stream: streams, status: status
  end

  def respond_ok
    respond_to do |f|
      f.turbo_stream { render_controls(achievement: latest_achievement, status: :ok) }
      f.html do
        flash[:notice] = "ごほうび解放！" if @new_rewards.present?
        redirect_to tasks_path(
          age_band:        params[:age_band],
          category:        params[:category],
          difficulty:      params[:difficulty],
          only_unachieved: params[:only_unachieved],
          page:            params[:page]
        )
      end
      f.json do
        a = latest_achievement
        render json: {
          id: a&.id,
          child_id: @child.id,
          milestone_id: @milestone.id,
          working: a&.working,
          achieved: a&.achieved,
          achieved_at: a&.achieved_at
        }, status: :ok
      end
    end
  end

  def respond_ng
    respond_to do |f|
      f.turbo_stream { render_controls(achievement: latest_achievement, status: :unprocessable_entity) }
      f.html { render plain: "unprocessable", status: :unprocessable_entity }
      f.json { render json: { error: "unprocessable" }, status: :unprocessable_entity }
    end
  end

  def respond_invalid_state
    respond_to do |f|
      f.turbo_stream { head :unprocessable_entity }
      f.html { render plain: "invalid state", status: :unprocessable_entity }
      f.json { render json: { error: "invalid state" }, status: :unprocessable_entity }
    end
  end
end