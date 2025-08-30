class AchievementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_child_and_milestone

  def upsert
    toggle = params[:toggle].to_s # "working" / "achieved" / "clear"
    ach    = @child.achievements.find_or_initialize_by(milestone_id: @milestone.id)

    # Pundit: 自分の記録だけ操作可
    authorize(ach, :upsert?)

    case toggle
    when "working"
      ach.working  = !ach.working
      ach.achieved = false if ach.working
      ach.achieved_at = nil unless ach.achieved
    when "achieved"
      ach.achieved = !ach.achieved
      ach.working  = false if ach.achieved
      ach.achieved_at = (ach.achieved ? Time.current : nil)
    when "clear"
      ach.working = false
      ach.achieved = false
      ach.achieved_at = nil
    end

    if !ach.working && !ach.achieved
      ach.destroy if ach.persisted?
    else
      ach.save!
    end

    # ← 追加：今回新たに解放されたごほうび（演出用）
    @new_rewards = RewardUnlocker.call(@child)
    ids = Array(@new_rewards).map(&:id)
    session[:reward_boot_ids] = ids if ids.any?

    respond_ok
  rescue ActiveRecord::RecordInvalid
    respond_ng
  end

  private

  def set_child_and_milestone
    @child = current_child
    # 子が未選択/他人の子を防ぐ
    raise Pundit::NotAuthorizedError, "invalid child" unless @child
    authorize @child, :use?  # ChildPolicy#use?

    @milestone = Milestone.find(params[:milestone_id])
  end

  def latest_achievement
    # 自分の範囲に限定（保険）
    policy_scope(Achievement).find_by(child_id: @child.id, milestone_id: @milestone.id)
  end

  # ---- レスポンス（Turbo / HTML 両対応） ----
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
          only_unachieved: params[:only_unachieved],
          page:            params[:page]
        )
      end
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