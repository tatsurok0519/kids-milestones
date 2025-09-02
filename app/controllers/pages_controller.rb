class PagesController < ApplicationController
  # 公開ページ（未ログインでも見せたいもの）だけ認証をスキップ
  # ApplicationController 側で authenticate_user! を強制していない環境でも安全な書き方にしておく
  skip_before_action :authenticate_user!,
                     only: %i[landing chat report growth_policy terms privacy],
                     raise: false

  before_action :set_landing_breadcrumb, only: :landing

  # --- 公開ページ ---
  def landing; end
  def chat; end
  def report; end
  def growth_policy; end

  # 追加：法務表示（静的ページ）
  def terms; end
  def privacy; end

  # --- マイページ（ゲストでも落ちないよう防御的に） ---
  def mypage
    if user_signed_in?
      if current_user.respond_to?(:children)
        @children = current_user.children.order(:id)
      else
        # 念のためのフォールバック（古い構成など）
        @children = Child.where(user_id: current_user.id).order(:id)
      end
    else
      @children = [] # ゲストは空配列。ビュー側でログイン導線を出す
    end
  end

  private

  def set_landing_breadcrumb
    return unless respond_to?(:add_crumb) # パンくず未導入環境で安全に無視

    path =
      if respond_to?(:unauthenticated_root_path)
        unauthenticated_root_path
      elsif respond_to?(:root_path)
        root_path
      elsif respond_to?(:landing_path)
        landing_path
      else
        url_for(controller: :pages, action: :landing, only_path: true)
      end

    add_crumb("ランディングページ", path)
  end
end