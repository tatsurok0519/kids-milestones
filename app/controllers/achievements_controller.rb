class AchievementsController < ApplicationController
  include TasksHelper
  before_action :authenticate_user!

  # どんな例外でも <turbo-frame> を返す（TurboのContent missing/500を防ぐ）
  around_action :wrap_with_frame_response

  before_action :set_child_and_milestone

  def upsert
    state = (params[:state].presence || params[:toggle].presence).to_s
    ach   = @child.achievements.find_or_initialize_by(milestone_id: @milestone.id)
    # authorize(ach, :upsert?)  # ← 一時停止（Punditが原因か切り分ける）

    case state
    when "working"
      ach.assign_attributes(working: !ach.working?, achieved: false, achieved_at: nil) if ach.working? || !ach.working?
    when "achieved"
      if ach.achieved?
        ach.assign_attributes(working: false, achieved: false, achieved_at: nil)
      else
        ach.assign_attributes(working: false, achieved: true)
        ach.achieved_at ||= Time.current
      end
    else
      return render_card_html(status: :unprocessable_entity, note: "invalid_state")
    end

    ach.save!

    # ごほうび関連は一旦停止（ここが500の起点になりやすい）
    @new_rewards = []  # ← とりあえず空（演出マーカーは出さない）

    render_card_html(status: :ok, note: "ok-min")
  end

  private

  def set_child_and_milestone
    @child = params[:child_id].present? ? Child.find(params[:child_id]) : current_child
    raise Pundit::NotAuthorizedError, "invalid child" unless @child
    # authorize @child, :use?  # ← 一時停止
    @milestone = Milestone.find(params.require(:milestone_id))
  end

  def latest_achievement_silent
    return nil unless @child && @milestone
    Achievement.where(child_id: @child.id, milestone_id: @milestone.id).first
  rescue
    nil
  end

  # ---- “必ずフレームHTMLで返す” 保険 ----
  def wrap_with_frame_response
    yield
  rescue => e
    Rails.logger.error("[achievements#upsert] rescued #{e.class}: #{e.message}")
    render_card_html(status: :internal_server_error, note: "rescued")
  end

  def render_card_html(status:, note:)
    # milestoneが取れない状況も想定して守りを固く
    @milestone ||= Milestone.find_by(id: params[:milestone_id])
    frame_id = request.headers["Turbo-Frame"].presence || task_card_frame_id(@milestone) || "card_milestone_#{params[:milestone_id]}"
    Rails.logger.info("[ach-upsert] status=#{status} note=#{note} hdr.Turbo-Frame=#{request.headers['Turbo-Frame']} frame_id=#{frame_id}")

    if @milestone
      render partial: "tasks/card",
             locals:  { milestone: @milestone, achievement: latest_achievement_silent, new_rewards: @new_rewards },
             layout: false,
             status: status
    else
      html = view_context.tag.turbo_frame(id: frame_id) { view_context.content_tag(:div, "更新できませんでした", style: "padding:.6rem;") }
      render html: html, layout: false, status: status
    end
  end
end