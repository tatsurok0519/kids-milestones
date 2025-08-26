class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_user_object

  def show
    @children = current_user.children.with_attached_photo.order(:created_at)
    @selected_child = @children.find_by(id: params[:child_id]) || @children.first

    if @selected_child
      @months = @selected_child.age_in_months
      @weeks  = @selected_child.age_in_weeks
      @flower_count = @selected_child.achievements.where(achieved: true).count
      @recommendations = RecommendationPicker.for_child(@selected_child, k: 3)
    else
      @recommendations = []
    end
  end

  private

  def ensure_user_object
    # Deviseのセッション復元に問題がある場合、current_userがArrayになることがある
    # この場合、ユーザーを強制的にサインアウトさせて再ログインを促す
    return if current_user.is_a?(User)

    sign_out
    redirect_to new_user_session_path, alert: 'セッション情報が正しくありません。お手数ですが、再度ログインしてください。'
  end
end