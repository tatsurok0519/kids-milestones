class AchievementsController < ApplicationController
  include TasksHelper
  before_action :authenticate_user!
  around_action  :wrap_with_frame_response
  before_action  :set_child_and_milestone

  # POST /achievements/upsert
  # params:
  #   milestone_id [req]
  #   toggle or state: "working" | "achieved"
  #   (dev) debug_reward=1  … 強制でトーストを出す検証用フラグ
  def upsert
    state = (params[:state].presence || params[:toggle].presence).to_s
    ach   = @child.achievements.find_or_initialize_by(milestone_id: @milestone.id)
    # authorize(ach, :upsert?) # ← Pundit を使う場合は有効化

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

    # -------- ごほうび判定（安全ラップ）--------
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
      @new_rewards = []  # 失敗しても画面更新は継続
    end

    # --- 開発用: 強制でトーストを出して演出確認したい時だけ ---
    if params[:debug_reward].present? && @new_rewards.blank?
      @new_rewards = [Reward.where(kind: %w[medal trophy special]).first].compact
    end

    render_card_html(status: :ok, note: "ok")
  end

  private

  # どこで例外が出ても “必ず” フレームHTMLで返す
  def wrap_with_frame_response
    yield
  rescue => e
    Rails.logger.error("[achievements#upsert] rescued #{e.class}: #{e.message}")
    render_card_html(status: :internal_server_error, note: "rescued")
  end

  def set_child_and_milestone
    @child =
      if params[:child_id].present?
        Child.find(params[:child_id])
      else
        current_child
      end
    raise Pundit::NotAuthorizedError, "invalid child" unless @child
    # authorize @child, :use? # ← Punditを使う場合は有効化

    @milestone = Milestone.find(params.require(:milestone_id))
  end

  def latest_achievement_silent
    return nil unless @child && @milestone
    Achievement.where(child_id: @child.id, milestone_id: @milestone.id).first
  rescue
    nil
  end

  # 呼び出し元 <turbo-frame> に確実に応答する
  def render_card_html(status:, note:)
    @milestone ||= Milestone.find_by(id: params[:milestone_id])

    # Turbo の期待フレームIDに合わせる（ヘッダ優先）
    frame_id = request.headers["Turbo-Frame"].presence ||
               task_card_frame_id(@milestone) ||
               "card_milestone_#{params[:milestone_id]}"

    Rails.logger.info("[ach-upsert] status=#{status} note=#{note} hdr.Turbo-Frame=#{request.headers['Turbo-Frame']} frame_id=#{frame_id}")

    if @milestone
        render partial: "tasks/card",
              locals: { milestone: @milestone, achievement: latest_achievement_silent, new_rewards: @new_rewards },
              layout: false, status: status
    else
      # milestone すら取得失敗時の最終保険
      html = view_context.tag.turbo_frame(id: frame_id) do
        view_context.content_tag(:div, "更新できませんでした", style: "padding:.6rem;")
      end
      render html: html, layout: false, status: status
    end
  end
end