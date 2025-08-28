class AchievementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_child_and_milestone

  def upsert
    toggle = params[:toggle].to_s # "working" or "achieved"
    ach    = @child.achievements.find_or_initialize_by(milestone_id: @milestone.id)

    case toggle
    when "working"
      ach.working  = !ach.working
      ach.achieved = false if ach.working
      ach.achieved_at = nil unless ach.achieved
    when "achieved"
      ach.achieved = !ach.achieved
      ach.working  = false if ach.achieved
      ach.achieved_at = (ach.achieved ? Time.current : nil)
    end

    if !ach.working && !ach.achieved && ach.persisted?
      ach.destroy
    else
      ach.save!
    end

    respond_ok
  rescue ActiveRecord::RecordInvalid
    respond_ng
  end

  private

  def set_child_and_milestone
    @child     = current_child
    @milestone = Milestone.find(params[:milestone_id])
  end

  def latest_achievement
    @child.achievements.find_by(milestone_id: @milestone.id)
  end

  # ---- レスポンス（Turbo / HTML 両対応） ----
  def respond_ok
    respond_to do |f|
      f.turbo_stream { render_controls(achievement: latest_achievement, status: :ok) }
      f.html         { redirect_to tasks_path(age_band: params[:age_band]) }
    end
  end

  def respond_ng
    respond_to do |f|
      f.turbo_stream { render_controls(achievement: latest_achievement, status: :unprocessable_entity) }
      f.html         { redirect_to tasks_path(age_band: params[:age_band]) }
    end
  end

  # 対象フレームを差し替える
  def render_controls(achievement:, status:)
    render turbo_stream: turbo_stream.update(
      view_context.dom_id(@milestone, :controls),
      partial: "tasks/controls",
      locals:  { milestone: @milestone, achievement: achievement }
    ), status: status
  end
end