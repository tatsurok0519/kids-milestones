class AchievementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_child_and_milestone

  def upsert
    # "working" / "achieved" / "clear"
    toggle = params[:toggle].to_s

    # 子ども未選択の安全対策（通常は到達しない想定）
    unless @child
      return respond_ng
    end

    ach = @child.achievements.find_or_initialize_by(milestone_id: @milestone.id)

    case toggle
    when "working"
      # 取組み中をトグル。ON時は達成を必ずOFFに
      ach.working = !ach.working
      if ach.working
        ach.achieved    = false
        ach.achieved_at = nil
      else
        ach.achieved_at = nil unless ach.achieved
      end

    when "achieved"
      # 達成をトグル。ON時は取組み中を必ずOFFに
      ach.achieved = !ach.achieved
      if ach.achieved
        ach.working     = false
        ach.achieved_at = Time.current
      else
        ach.achieved_at = nil
      end

    when "clear"
      # 明示的に未着手へ戻す
      ach.working     = false
      ach.achieved    = false
      ach.achieved_at = nil

    else
      return respond_ng
    end

    # どちらもOFFならレコード削除（未着手の表現）
    if !ach.working && !ach.achieved
      ach.destroy if ach.persisted?
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
    @child&.achievements&.find_by(milestone_id: @milestone.id)
  end

  # ---- レスポンス（Turbo / HTML 両対応） ----
  def respond_ok
    respond_to do |f|
      f.turbo_stream { render_controls(achievement: latest_achievement, status: :ok) }
      f.html do
        redirect_to tasks_path(
          age_band:        params[:age_band],
          category:        params[:category],
          difficulty:      params[:difficulty],
          only_unachieved: params[:only_unachieved]
        )
      end
    end
  end

  def respond_ng
    respond_to do |f|
      f.turbo_stream { render_controls(achievement: latest_achievement, status: :unprocessable_entity) }
      f.html do
        redirect_to tasks_path(
          age_band:        params[:age_band],
          category:        params[:category],
          difficulty:      params[:difficulty],
          only_unachieved: params[:only_unachieved]
        )
      end
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