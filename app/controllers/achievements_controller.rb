class AchievementsController < ApplicationController
  include TasksHelper  # task_card_frame_id を使う
  before_action :authenticate_user!
  before_action :set_child_and_milestone

  def upsert
    state = (params[:state].presence || params[:toggle].presence).to_s
    ach   = @child.achievements.find_or_initialize_by(milestone_id: @milestone.id)
    authorize(ach, :upsert?)

    case state
    when "working"
      ach.working? ?
        ach.assign_attributes(working: false) :
        ach.assign_attributes(working: true, achieved: false, achieved_at: nil)
    when "achieved"
      ach.achieved? ?
        ach.assign_attributes(working: false, achieved: false, achieved_at: nil) :
        ach.assign_attributes(working: false, achieved: true).tap { ach.achieved_at ||= Time.current }
    else
      return render_card_html(status: :unprocessable_entity)
    end

    ach.save!

    @new_rewards = RewardUnlocker.call(@child)
    if @new_rewards.present?
      ids = @new_rewards.map(&:id)
      session[:unseen_reward_ids] = (Array(session[:unseen_reward_ids]) + ids).uniq
    end

    render_card_html(status: :ok)

  rescue ActiveRecord::RecordNotFound
    render_card_html(status: :not_found)
  rescue Pundit::NotAuthorizedError
    render_card_html(status: :forbidden)
  rescue ActiveRecord::RecordInvalid
    render_card_html(status: :unprocessable_entity)
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

  # いつでもフレームHTML（tasks/_card）を返す
  def render_card_html(status:)
    Rails.logger.info("[upsert] Turbo-Frame=#{request.headers['Turbo-Frame']} expected=#{task_card_frame_id(@milestone)}")
    render partial: "tasks/card",
           locals:  { milestone: @milestone, achievement: latest_achievement },
           layout:  false,
           status:  status
  end
end