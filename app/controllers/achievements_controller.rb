class AchievementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_child_and_milestone

  def upsert
    request.format = :turbo_stream if turbo_frame_request?

    state = (params[:state].presence || params[:toggle].presence).to_s
    ach   = @child.achievements.find_or_initialize_by(milestone_id: @milestone.id)
    authorize(ach, :upsert?)

    case state
    when "working"
      ach.assign_attributes(
        working:  !ach.working?,
        achieved: false,
        achieved_at: nil
      )
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

    # 新規解放リワード（演出用）
    @new_rewards = RewardUnlocker.call(@child)
    ids = Array(@new_rewards).map(&:id)

    # ▼ ここを追加：未視聴としてセッションに貯める（加算/ユニーク）
    if ids.any?
      unseen = Array(session[:unseen_reward_ids])
      session[:unseen_reward_ids] = (unseen + ids).uniq
    end

    respond_ok
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("[achievements#upsert] 404 child/milestone not found")
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
    @child = params[:child_id].present? ? Child.find(params[:child_id]) : current_child
    raise Pundit::NotAuthorizedError, "invalid child" unless @child
    authorize @child, :use?

    @milestone = Milestone.find(params.require(:milestone_id))
  end

  def latest_achievement
    policy_scope(Achievement).find_by(child_id: @child.id, milestone_id: @milestone.id)
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
          id: a&.id, child_id: a&.child_id || @child.id,
          milestone_id: @milestone.id,
          working: a&.working, achieved: a&.achieved, achieved_at: a&.achieved_at
        }, status: :ok
      end
    end
  end

  def respond_ng
    respond_to do |f|
      f.turbo_stream { render_controls(achievement: latest_achievement, status: :unprocessable_entity) }
      f.html  { render plain: "unprocessable", status: :unprocessable_entity }
      f.json  { render json: { error: "unprocessable" }, status: :unprocessable_entity }
    end
  end

  def respond_invalid_state
    respond_to do |f|
      f.turbo_stream { head :unprocessable_entity }
      f.html  { render plain: "invalid state", status: :unprocessable_entity }
      f.json  { render json: { error: "invalid state" }, status: :unprocessable_entity }
    end
  end

  def render_controls(achievement:, status:)
    streams = []
    streams << turbo_stream.update(
      view_context.dom_id(@milestone, :controls),
      partial: "tasks/controls",
      locals:  { milestone: @milestone, achievement: achievement }
    )
    if @new_rewards.present?
      streams << turbo_stream.append(
        "toasts",
        partial: "shared/reward_toast",
        locals:  { rewards: @new_rewards }
      )
    end
    render turbo_stream: streams, status: status
  end
end