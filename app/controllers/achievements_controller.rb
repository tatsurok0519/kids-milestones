class AchievementsController < ApplicationController
  include TasksHelper
  before_action :authenticate_user!
  before_action :set_child_and_milestone

  # どんな状況でもカードの <turbo-frame> を返す（Turbo Stream は使わない）
  def upsert
    begin
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

      # ごほうび（必要ならセッションへ）
      @new_rewards = RewardUnlocker.call(@child)
      if @new_rewards.present?
        ids = @new_rewards.map(&:id)
        session[:unseen_reward_ids] = (Array(session[:unseen_reward_ids]) + ids).uniq
      end

      render_card_html(status: :ok, note: "ok")
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.warn("[achievements#upsert] 404 #{e.message}")
      render_card_html(status: :not_found, note: "not_found")
    rescue Pundit::NotAuthorizedError => e
      Rails.logger.warn("[achievements#upsert] 403 #{e.message}")
      render_card_html(status: :forbidden, note: "forbidden")
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn("[achievements#upsert] 422 #{e.record.errors.full_messages.join(', ')}")
      render_card_html(status: :unprocessable_entity, note: "invalid_record")
    rescue StandardError => e
      # 予期しない例外でも必ずフレームHTMLを返す
      Rails.logger.error("[achievements#upsert] 500 #{e.class}: #{e.message}")
      render_card_html(status: :internal_server_error, note: "exception")
    end
  end

  private

  def set_child_and_milestone
    @child = params[:child_id].present? ? Child.find(params[:child_id]) : current_child
    raise Pundit::NotAuthorizedError, "invalid child" unless @child
    authorize @child, :use?
    @milestone = Milestone.find(params.require(:milestone_id))
  end

  def latest_achievement
    policy_scope(Achievement).find_by(child_id: @child.id, milestone_id: @milestone.id)
  end

  # 期待フレームID（ビューと厳密一致）
  def card_frame_id
    task_card_frame_id(@milestone) # => "card_milestone_#{@milestone.id}"
  end

  # つねに <turbo-frame> HTML（tasks/_card）を返す
  def render_card_html(status:, note:)
    Rails.logger.info("[ach-upsert] hdr.Turbo-Frame=#{request.headers['Turbo-Frame']} expected=#{card_frame_id} note=#{note}")
    render partial: "tasks/card",
           locals:  { milestone: @milestone, achievement: latest_achievement },
           layout:  false,
           status:  status
  end
end