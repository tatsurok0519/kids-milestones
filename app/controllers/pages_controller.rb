class PagesController < ApplicationController
  # 公開ページ（未ログインでも見せたいもの）は認証スキップ
  skip_before_action :authenticate_user!,
                     only: %i[landing chat report growth_policy terms privacy dismiss_banner],
                     raise: false

  before_action :set_landing_breadcrumb, only: :landing

  # --- 公開ページ ---
  def landing; end
  def chat; end
  def report; end
  def growth_policy; end
  def terms; end
  def privacy; end

  # --- マイページ（ゲストでも落ちないよう防御的に） ---
  def mypage
    if user_signed_in?
      if current_user.respond_to?(:children)
        @children = current_user.children.order(:id)
      else
        @children = Child.where(user_id: current_user.id).order(:id)
      end
    else
      @children = []
    end
  end

  # --- ガイドの×で閉じる（セッションに記録 & その場で非表示） ---
  def dismiss_banner
    session[:hide_growth_banner] = true
    respond_to do |f|
      # #growth-policy-banner をDOMから外す
      f.turbo_stream { render turbo_stream: turbo_stream.remove("growth-policy-banner") }
      f.html { redirect_back fallback_location: root_path }
      f.json { render json: { ok: true }, status: :ok }
    end
  end

  private

  def set_landing_breadcrumb
    return unless respond_to?(:add_crumb)

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

    add_crumb("はじめに", path)
  end
end