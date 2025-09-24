class AchievementsController < ApplicationController
  include TasksHelper
  before_action :authenticate_user!

  # 通常の set_* より前に “必ずフレームで返す” 保険を張る
  around_action :wrap_with_frame_response

  before_action :set_child_and_milestone

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
      return render_card_html(status: :unprocessable_entity, note: "invalid_state")
    end

    ach.save!

    # 新規解放のごほうび（配列 or []）
    @new_rewards = Array(RewardUnlocker.call(@child))
    if @new_rewards.present?
      ids = @new_rewards.map(&:id)
      session[:unseen_reward_ids] = (Array(session[:unseen_reward_ids]) + ids).uniq
    end

    render_card_html(status: :ok, note: "ok")
  end

  private

  # --- ここが肝：例外でも必ずカードHTMLで返す -----------------------------

  def wrap_with_frame_response
    yield
  rescue Pundit::NotAuthorizedError => e
    log_ex(e, 403)
    render_card_html(status: :forbidden, note: "forbidden")
  rescue ActiveRecord::RecordNotFound => e
    log_ex(e, 404)
    render_card_html(status: :not_found, note: "not_found")
  rescue ActiveRecord::RecordInvalid => e
    log_ex(e, 422, details: e.record.errors.full_messages.join(", "))
    render_card_html(status: :unprocessable_entity, note: "invalid_record")
  rescue StandardError => e
    log_ex(e, 500)
    render_card_html(status: :internal_server_error, note: "exception")
  end

  def log_ex(e, code, details: nil)
    Rails.logger.error("[achievements#upsert] #{code} #{e.class}: #{e.message} #{details}")
  end

  # 呼び出し元フレームに確実に応答する
  def render_card_html(status:, note:)
    # “万一” set_* が失敗していても安全に復旧
    @milestone ||= Milestone.find_by(id: params[:milestone_id])
    @child     ||= current_child

    Rails.logger.info("[ach-upsert] hdr.Turbo-Frame=#{request.headers['Turbo-Frame']} expected=#{task_card_frame_id(@milestone) if @milestone} note=#{note}")

    # milestone が取れない場合でも、フレームIDだけは合わせる
    if @milestone
      render partial: "tasks/card",
             locals:  { milestone: @milestone,
                        achievement: latest_achievement_silent,
                        new_rewards: @new_rewards },
             layout: false,
             status: status
    else
      # 最低限の空フレームで返す（Turbo の Content missing を防ぐ）
      frame_id = request.headers["Turbo-Frame"].presence || "card_milestone_#{params[:milestone_id]}"
      html = view_context.tag.turbo_frame(id: frame_id) do
        view_context.content_tag(:div, "更新できませんでした", style: "padding:.6rem;")
      end
      render html: html, layout: false, status: status
    end
  end

  # --- 通常の finder ---------------------------------------------------------

  def set_child_and_milestone
    @child =
      if params[:child_id].present?
        Child.find(params[:child_id])
      else
        current_child || (raise Pundit::NotAuthorizedError, "invalid child")
      end
    authorize @child, :use?

    @milestone = Milestone.find(params.require(:milestone_id))
  end

  def latest_achievement_silent
    return nil unless @child && @milestone
    policy_scope(Achievement).find_by(child_id: @child.id, milestone_id: @milestone.id)
  rescue
    nil
  end
end