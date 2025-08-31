class PagesController < ApplicationController
  # 公開で見せたいので、認証は強制しない
  skip_before_action :authenticate_user!, raise: false
  before_action :set_landing_breadcrumb, only: :landing

  def landing; end
  def chat;  end
  def report; end
  def growth_policy; end

  def mypage
    # 未ログインでも落ちないように分岐
    if user_signed_in?
      if current_user.respond_to?(:children)
        @children = current_user.children.order(:id)
      else
        # 念のためのフォールバック（古い構成など）
        @children = Child.where(user_id: current_user.id).order(:id)
      end
    else
      @children = [] # ゲストは空配列。ビューでCTAを出す
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