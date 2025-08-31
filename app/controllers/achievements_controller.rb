class AchievementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_child_and_milestone

  # POST /achievements/upsert
  # 受け付けるパラメータ:
  # - state  または toggle: "working" | "achieved" | "clear"
  # - child_id（任意）：なければ current_child を使用
  # - milestone_id（必須）
  # - 画面フィルタ維持用: age_band/category/difficulty/only_unachieved/page
  def upsert
    # UI/テスト両対応（toggle/state どちらでもOK）
    state = (params[:state].presence || params[:toggle].presence).to_s

    ach = @child.achievements.find_or_initialize_by(milestone_id: @milestone.id)
    # Pundit: 自分の記録だけ操作可
    authorize(ach, :upsert?)

    case state
    when "working"
      # テスト契約：明示的に working=true / achieved=false / achieved_at=nil
      ach.working     = true
      ach.achieved    = false
      ach.achieved_at = nil

    when "achieved"
      # 初回のみ打刻（冪等性を担保）
      ach.working  = false
      ach.achieved = true
      ach.achieved_at ||= Time.current

    when "clear"
      # テスト契約：レコードは削除せず保持（全クリア）
      ach.working     = false
      ach.achieved    = false
      ach.achieved_at = nil

    else
      # 不正な state/toggle
      return respond_invalid_state
    end

    ach.save!

    # 新たに解放されたごほうび（演出用）
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
    # child_id が来ていればそれを優先、無ければ current_child を使う
    # → 他人の child_id の場合は authorize で 403 を返す
    @child = if params[:child_id].present?
               Child.find(params[:child_id])
             else
               current_child
             end
    raise Pundit::NotAuthorizedError, "invalid child" unless @child
    authorize @child, :use?  # ChildPolicy#use?

    @milestone = Milestone.find(params.require(:milestone_id))
  end

  def latest_achievement
    # 自分の範囲に限定（保険）
    policy_scope(Achievement).find_by(child_id: @child.id, milestone_id: @milestone.id)
  end

  # ---- レスポンス（Turbo / HTML / JSON 対応） ----
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
        # 422 を返す（テスト互換）。UI都合でリダイレクトしたい場合はここを redirect_to に戻してOK
        render plain: "unprocessable", status: :unprocessable_entity
      end
      f.json { render json: { error: "unprocessable" }, status: :unprocessable_entity }
    end
  end

  def respond_invalid_state
    respond_to do |f|
      f.turbo_stream { head :unprocessable_entity }
      f.html        { render plain: "invalid state", status: :unprocessable_entity }
      f.json        { render json: { error: "invalid state" }, status: :unprocessable_entity }
    end
  end

  # 対象フレームを差し替える + 新規解放があればトーストを追加
  def render_controls(achievement:, status:)
    streams = []
    streams << turbo_stream.update(
      view_context.dom_id(@milestone, :controls),
      partial: "tasks/controls",
      locals:  { milestone: @milestone, achievement: achievement }
    )

    if @new_rewards.present?
      streams << turbo_stream.append(
        # レイアウトにある <div id="toasts" class="toast-layer"> … </div> に挿入
        "toasts",
        partial: "shared/reward_toast",
        locals:  { rewards: @new_rewards }
      )
    end

    render turbo_stream: streams, status: status
  end
end