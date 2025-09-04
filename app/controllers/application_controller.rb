class ApplicationController < ActionController::Base
  include Devise::Controllers::Helpers
  include Pundit::Authorization
  include Breadcrumbs
  include SqlProfiler

  # ※ グローバルの authenticate_user! は使わない（各コントローラで必要時に指定）
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :basic_auth, if: :basic_auth_applicable?
  before_action :set_current_child
  before_action :expose_unseen_rewards

  helper_method :current_child

  # --- 認可エラーの共通ハンドリング ---
  rescue_from Pundit::NotAuthorizedError do |_e|
    respond_to do |f|
      f.turbo_stream { head :forbidden }
      f.html { redirect_to "/403" }
      f.json { render json: { error: "forbidden" }, status: :forbidden }
    end
  end

  protect_from_forgery with: :exception

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up,        keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  def after_sign_in_path_for(_resource)
    authenticated_root_path
  end

  def after_sign_out_path_for(_scope)
    unauthenticated_root_path
  end

  private

  # 未視聴リワードIDを「非破壊で」公開（既読クリアは RewardsController#ack_seen のみ）
  def expose_unseen_rewards
    ids = Array(session[:unseen_reward_ids]).map(&:to_i).uniq
    @reward_boot_ids   = ids
    @unseen_reward_ids = ids
  end

  # 現在選択中の子（nil 可）
  def current_child
    return @current_child if defined?(@current_child)

    cid = session[:current_child_id]
    @current_child = Child.find_by(id: cid) if cid.present?

    # すでに削除されていたらセッションを掃除して nil を返す
    if cid.present? && @current_child.nil?
      session.delete(:current_child_id)
    end
    @current_child
  end

  # 選択変更用のヘルパ（任意）
  def select_current_child(child)
    if child.present?
      session[:current_child_id] = child.id
      @current_child = child
    else
      session.delete(:current_child_id)
      @current_child = nil
    end
  end

  # 自分の子のみをポリシースコープで取得し、セッションの child_id を検証・同期
  def set_current_child
    return unless current_user

    @children = policy_scope(Child).with_attached_photo.order(:created_at)

    @current_child =
      if session[:current_child_id].present?
        @children.find_by(id: session[:current_child_id]) || @children.first
      else
        @children.first
      end

    session[:current_child_id] = @current_child&.id
    @selected_child = @current_child
  end

  # --- 本番での Basic 認証をかける/外す判定（安全版） ---
  def basic_auth_applicable?
    return false unless Rails.env.production?
    return false unless ENV["BASIC_AUTH_USER"].present? && ENV["BASIC_AUTH_PASSWORD"].present?

    # Devise 画面は全除外（ログイン/登録/パス再発行などがブロックされない）
    return false if devise_controller?

    path = request.path.to_s
    # ヘルスチェックや静的配信は除外
    return false if path == "/up"
    return false if path.start_with?("/assets", "/packs", "/rails/active_storage")

    true
  end

  def basic_auth
    authenticate_or_request_with_http_basic("Restricted") do |user, pass|
      ActiveSupport::SecurityUtils.secure_compare(user.to_s, ENV.fetch("BASIC_AUTH_USER")) &&
        ActiveSupport::SecurityUtils.secure_compare(pass.to_s, ENV.fetch("BASIC_AUTH_PASSWORD"))
    end
  end
end