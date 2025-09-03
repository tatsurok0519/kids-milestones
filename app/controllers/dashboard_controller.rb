class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_user_object
  before_action :load_children
  before_action :select_child
  before_action -> { add_crumb("メイン", dashboard_path) }

  def show
    @child = @selected_child # nil 可

    # 子どもごとの達成数（一覧/切替UI・選択中の子の表示にも流用）
    @achieved_counts =
      Achievement.where(child_id: @children.select(:id), achieved: true)
                 .group(:child_id).count

    # 選択中の子の花丸（可能なら↑の結果を利用して追加クエリを避ける）
    @achieved_count = @child ? (@achieved_counts[@child.id] || 0) : 0

    # ごほうび（UI用の全マスタ）。テーブルが小さい想定なので素直に取得
    @rewards = Reward.order(:threshold, :tier, :id).to_a

    # 選択中の子の解放済みごほうび ID を 1 クエリで
    @reward_unlock_ids =
      @child ? RewardUnlock.where(child_id: @child.id).pluck(:reward_id) : []

    # 年齢表示（必要ならビューで使用）
    @age_label = @child&.age_years_and_months

    # 今日の子育てメッセージ（障害時は安全な既定文にフォールバック）
    @parent_tip =
      begin
        ParentTip.for(child: @child, date: Date.current)
      rescue => e
        Rails.logger.warn("[dashboard#show] ParentTip fallback: #{e.class}: #{e.message}")
        "あせらず、できることからやってみましょう。"
      end
  end

  private

  # ログインユーザーの子ども一覧（写真を一括先読み）
  def load_children
    @children = policy_scope(Child).with_attached_photo.order(:created_at)
  end

  # child_id が来たらそれを選択。無ければ セッション→先頭 の順で決定
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

  # セッション保護（異常時はサインアウトして再ログインを促す）
  def ensure_user_object
    return if current_user.is_a?(User)

    sign_out
    redirect_to(
      new_user_session_path,
      alert: "セッション情報が正しくありません。お手数ですが、再度ログインしてください。"
    )
  end
end