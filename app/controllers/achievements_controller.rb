class AchievementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_child_and_milestone

  # POST /achievements/upsert
  # パラメータ:
  #   - milestone_id  [必須]
  #   - toggle or state: "working" / "achieved"
  #   - 画面復帰用: age_band, category, difficulty, only_unachieved, page
  def upsert
    state = (params[:state].presence || params[:toggle].presence).to_s
    ach   = @child.achievements.find_or_initialize_by(milestone_id: @milestone.id)
    authorize(ach, :upsert?)

    case state
    when "working"
      # トグル: working を反転。achieved は落とす
      if ach.working?
        ach.assign_attributes(working: false)
      else
        ach.assign_attributes(working: true, achieved: false, achieved_at: nil)
      end

    when "achieved"
      # トグル: achieved を反転。ON にする時は working を落として achieved_at を付与
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

    # ごほうびの解放判定（今回「新しく」解放されたものだけが返る）
    @new_rewards = RewardUnlocker.call(@child)

    # ← 追加：このリクエストで何個解放されたかを記録
    Rails.logger.info(
      "[ach-upsert] child=#{@child.id} achieved_count=#{@child.achievements.where(achieved: true).count} " \
      "new_reward_ids=#{Array(@new_rewards).map(&:id)}"
    )

    # 演出を別ページでも起動できるよう、未表示IDをセッションに積む
    if @new_rewards.present?
      ids = @new_rewards.map(&:id)
      session[:unseen_reward_ids] = (Array(session[:unseen_reward_ids]) + ids).uniq
    end

    respond_ok

  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("[achievements#upsert] 404 child or milestone not found")
    head :not_found

  rescue Pundit::NotAuthorizedError
    Rails.logger.warn("[achievements#upsert] 403 not authorized")
    head :forbidden

  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn("[achievements#upsert] 422 #{e.record.errors.full_messages.join(', ')}")
    respond_ng
  end

  private

  # ---- helpers --------------------------------------------------------------

  def set_child_and_milestone
    @child =
      if params[:child_id].present?
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

  # Turbo Stream でボタン群を書き換え & 演出トリガ送出
  def render_controls(achievement:, status:)
    streams = []

    # 1) 対象カードのコントロールを差し替え
    streams << turbo_stream.update(
      view_context.dom_id(@milestone, :controls),
      partial: "tasks/controls",
      locals:  { milestone: @milestone, achievement: achievement }
    )

    if @new_rewards.present?
      # 2) トーストを積む（UI）
      streams << turbo_stream.append(
        "toasts",
        partial: "shared/reward_toast",
        locals:  { rewards: @new_rewards }
      )

      # 3) ★ 演出の合図用に、不可視ターゲットへ data-* を書き込む
      ids_csv = @new_rewards.map(&:id).join(",")
      marker  = view_context.tag.div(nil, data: { reward_unlocked: ids_csv })
      streams << turbo_stream.update("reward_animator", marker)
    end

    render turbo_stream: streams, status: status
  end

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
          child_id: @child.id,
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
      f.html { render plain: "unprocessable", status: :unprocessable_entity }
      f.json { render json: { error: "unprocessable" }, status: :unprocessable_entity }
    end
  end

  def respond_invalid_state
    respond_to do |f|
      f.turbo_stream { head :unprocessable_entity }
      f.html { render plain: "invalid state", status: :unprocessable_entity }
      f.json { render json: { error: "invalid state" }, status: :unprocessable_entity }
    end
  end
end