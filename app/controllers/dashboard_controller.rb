class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_user_object
  before_action :load_children
  before_action :select_child
  before_action -> { add_crumb("ダッシュボード", dashboard_path) }

  def show
    @child = @selected_child # nil 可

    # 花丸（達成）数
    @achieved_count = if @child
                         Achievement.where(child_id: @child.id, achieved: true).count
                       else
                         0
                       end

    # ごほうび表示用
    @rewards = Reward.order(:threshold, :tier, :id).to_a
    @reward_unlock_ids = if @child
                           RewardUnlock.where(child_id: @child.id).pluck(:reward_id)
                         else
                           []
                         end

    # 子どもごとの達成数（一覧/切替UIで使用）
    @achieved_counts =
      Achievement.where(child_id: @children.ids, achieved: true).group(:child_id).count

    # 年齢表示
    @age_label = @child&.age_years_and_months

    # 今日の子育てメッセージ
    @parent_tip = ParentTip.for(child: @child, date: Date.current)
  end

  private

  # ログインユーザーの子ども一覧（写真先読み）
  def load_children
    @children = policy_scope(Child).with_attached_photo.order(:created_at)
  end

  # child_id が来たらそれを選択。無ければ セッション→先頭 の順
  def select_child
    if params[:child_id].present?
      if (kid = @children.find_by(id: params[:child_id]))
        session[:current_child_id] = kid.id
        @current_child = kid
      end
    end

    @current_child ||= begin
      if session[:current_child_id].present?
        @children.find_by(id: session[:current_child_id])
      else
        respond_to?(:current_child) ? current_child : nil
      end
    end

    @selected_child = @current_child || @children.first
  end

  def ensure_user_object
    return if current_user.is_a?(User)

    sign_out
    redirect_to(new_user_session_path, alert: "セッション情報が正しくありません。お手数ですが、再度ログインしてください。")
  end
end