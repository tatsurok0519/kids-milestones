class AchievementsController < ApplicationController
  include TasksHelper
  before_action :authenticate_user!
  before_action :set_child_and_milestone

  # POST /achievements/upsert
  # params:
  #   milestone_id [req]
  #   toggle or state: "working" | "achieved"
  #   (dev) debug_reward=1  … 演出確認用の強制トースト
  def upsert
    state = (params[:state].presence || params[:toggle].presence).to_s

    ach = @child.achievements.find_or_initialize_by(milestone_id: @milestone.id)

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
      return render_stream_error(:unprocessable_entity, "invalid_state")
    end

    ach.save!

    # --- ごほうび判定（失敗しても画面更新は継続）---
    @new_rewards = []
    begin
      unlocked     = RewardUnlocker.call(@child)
      @new_rewards = Array(unlocked).compact
      if @new_rewards.present?
        session[:unseen_reward_ids] =
          (Array(session[:unseen_reward_ids]) + @new_rewards.map(&:id)).uniq
      end
    rescue => e
      Rails.logger.error("[RewardUnlocker] #{e.class}: #{e.message}")
      @new_rewards = []
    end

    # 開発用: 強制トースト
    if params[:debug_reward].present? && @new_rewards.blank?
      @new_rewards = [Reward.where(kind: %w[medal trophy special]).first].compact
    end

    respond_to do |format|
      format.turbo_stream do
        # フレーム内の中身だけ更新（フレームは維持）
        render turbo_stream: turbo_stream.update(
          task_card_frame_id(@milestone),
          partial: "tasks/controls",
          locals: { milestone: @milestone, achievement: ach }
        )
      end

      # 直叩きなど fallback
      format.html do
        redirect_back fallback_location: tasks_path, status: :see_other
      end
    end
  rescue => e
    Rails.logger.error("[achievements#upsert] rescued #{e.class}: #{e.message}")
    render_stream_error(:internal_server_error, "rescued")
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

    @milestone = Milestone.find(params.require(:milestone_id))
  end

  # 失敗時の共通応答（turbo/HTML両対応）
  def render_stream_error(status, note)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          task_card_frame_id(@milestone || Milestone.new(id: params[:milestone_id])),
          partial: "tasks/controls",
          locals: {
            milestone: (@milestone || Milestone.find_by(id: params[:milestone_id])),
            achievement: latest_achievement_silent
          },
          status: status
        )
      end
      format.html do
        redirect_back fallback_location: tasks_path, status: :see_other
      end
    end
  end

  def latest_achievement_silent
    return nil unless @child && @milestone
    Achievement.where(child_id: @child.id, milestone_id: @milestone.id).first
  rescue
    nil
  end
end