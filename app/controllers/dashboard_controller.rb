class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_user_object
  before_action :load_children
  before_action :select_child

  def show
    # 表示用
    @child        = @selected_child # nil 可
    @age_label    = @child&.age_years_and_months
    @flower_count = @child ? @child.achievements.where(achieved: true).count : 0

    # 子どもごとの達成数（一覧に表示する用）
    @achieved_counts = Achievement.where(child_id: @children.ids, achieved: true).group(:child_id).count

    # 今日の子育てメッセージ
    @parent_tip = ParentTip.for(child: @child, date: Date.current)
  end

  private

  # ログインユーザーの子ども一覧（写真付き）
  def load_children
    @children = current_user.children.with_attached_photo.order(:created_at)
  end

  # child_id があればそれを選択してセッションに保存
  # 無ければ セッション→current_child→先頭 の順に選ぶ
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