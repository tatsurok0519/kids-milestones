class AchievementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_child_and_milestone

  def upsert
    state = (params[:state].presence || params[:toggle].presence).to_s
    ach = @child.achievements.find_or_initialize_by(milestone_id: @milestone.id)
    authorize(ach, :upsert?)

    case state
    when "working"
      if ach.working? && !ach.achieved?
        ach.working     = false
        ach.achieved    = false
        ach.achieved_at = nil
      else
        ach.working     = true
        ach.achieved    = false
        ach.achieved_at = nil
      end
    when "achieved"
      if ach.achieved?
        ach.working     = false
        ach.achieved    = false
        ach.achieved_at = nil
      else
        ach.working     = false
        ach.achieved    = true
        ach.achieved_at ||= Time.current
      end
    when "clear"
      ach.working     = false
      ach.achieved    = false
      ach.achieved_at = nil
    else
      return respond_invalid_state
    end

    ach.save!

    @new_rewards = RewardUnlocker.call(@child)
    ids = Array(@new_rewards).map(&:id)
    session[:reward_boot_ids] = ids if ids.any?

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
    @child = if params[:child_id].present?
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

  def respond_ok
    respond_to do |f|
      f.turbo_stream { render_controls(achievement: latest_achievement, status: :ok) }
      f.html do
        if turbo_frame_request?
          # フレームからの送信ならフレームをそのまま差し替える（遷移しない）
          render partial: "tasks/controls_frame",
                 locals:  { milestone: @milestone, achievement: latest_achievement },
                 status:  :ok
        else
          flash[:notice] = "ごほうび解放！" if @new_rewards.present?
          redirect_to tasks_path(
            age_band:        params[:age_band],
            category:        params[:category],
            difficulty:      params[:difficulty],
            only_unachieved: params[:only_unachieved],
            page:            params[:page]
          )
        end
      end
      f.json do
        a = latest_achievement
        render json: {
          id: a&.id,
          child_id: a&.child_id || @child.id,
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
      f.html do
        if turbo_frame_request?
          render partial: "tasks/controls_frame",
                 locals:  { milestone: @milestone, achievement: latest_achievement },
                 status:  :unprocessable_entity
        else
          render plain: "unprocessable", status: :unprocessable_entity
        end
      end
      f.json { render json: { error: "unprocessable" }, status: :unprocessable_entity }
    end
  end

  def respond_invalid_state
    respond_to do |f|
      f.turbo_stream { head :unprocessable_entity }
      f.html do
        if turbo_frame_request?
          render partial: "tasks/controls_frame",
                 locals:  { milestone: @milestone, achievement: latest_achievement },
                 status:  :unprocessable_entity
        else
          render plain: "invalid state", status: :unprocessable_entity
        end
      end
      f.json { render json: { error: "invalid state" }, status: :unprocessable_entity }
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