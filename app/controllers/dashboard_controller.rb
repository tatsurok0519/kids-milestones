class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    # /dashboard?child_id=xxx で来たら、選択を更新してセッションに保存
    if params[:child_id].present?
      if (kid = current_user.children.find_by(id: params[:child_id]))
        session[:current_child_id] = kid.id
        @current_child   = kid
        @selected_child  = kid
      end
    end

    # 念のため（他ページから単独で呼ばれても崩れないよう補強）
    @children       ||= current_user.children.with_attached_photo.order(:created_at)
    @selected_child ||= @current_child

    return if @selected_child.blank?

    # 表示用
    @child       = @selected_child
    @age_label   = @selected_child.age_years_and_months
    @flower_count = @selected_child.achievements.count
    @recommendations = RecommendationPicker.for_child(@selected_child, k: 3)
  end

  def ensure_user_object
    # 既存のまま
    return if current_user.is_a?(User)

    sign_out
    redirect_to new_user_session_path, alert: 'セッション情報が正しくありません。お手数ですが、再度ログインしてください。'
  end
end