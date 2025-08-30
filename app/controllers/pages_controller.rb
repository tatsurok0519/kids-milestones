class PagesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  before_action :set_landing_breadcrumb, only: :landing

  def landing; end
  def chat;  end
  def report; end

  private

  def set_landing_breadcrumb
    # 利用可能なルートヘルパを順に探す（Devise構成でもOK）
    path =
      if respond_to?(:unauthenticated_root_path)
        unauthenticated_root_path
      elsif respond_to?(:root_path)
        root_path
      elsif respond_to?(:landing_path)
        landing_path
      else
        url_for(controller: :pages, action: :landing, only_path: true) # 最後の手段
      end

    add_crumb("ランディングページ", path)
  end
end