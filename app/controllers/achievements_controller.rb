class AchievementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_child_and_milestone

  def upsert
    state = (params[:state].presence || params[:toggle].presence).to_s
    ach   = @child.achievements.find_or_initialize_by(milestone_id: @milestone.id)
    authorize(ach, :upsert?)

    case state
    when "working"
      ach.assign_attributes(working: !ach.working?, achieved: false, achieved_at: nil)
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

    # 新規解放ごほうび → セッションへ積む
    @new_rewards = RewardUnlocker.call(@child)
    ids = Array(@new_rewards).map(&:id)
    if ids.any?
      unseen = Array(session[:unseen_reward_ids])
      session[:unseen_reward_ids] = (unseen + ids).uniq
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
    render_controls(achievement: latest_achievement, status: :ok)
  end

  def respond_ng
    render_controls(achievement: latest_achievement, status: :unprocessable_entity)
  end

  def respond_invalid_state
    respond_to do |f|
      f.turbo_stream { head :unprocessable_entity }
      f.html  { render plain: "invalid state", status: :unprocessable_entity }
      f.json  { render json: { error: "invalid state" }, status: :unprocessable_entity }
      f.any   { head :unprocessable_entity }
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
      ids_csv = @new_rewards.map(&:id).join(",")
      marker  = helpers.tag.div("", data: { reward_unlocked: ids_csv })
      streams << turbo_stream.update("reward_animator", marker)
    end

    render turbo_stream: streams,
           content_type: "text/vnd.turbo-stream.html",
           status: status
  end
end