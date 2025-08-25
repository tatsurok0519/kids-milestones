class ApplicationController < ActionController::Base
  before_action :basic_auth, if: :basic_auth_applicable?
  include BasicAuthProtection 
  before_action :authenticate_user! 

  private
  
  def after_sign_in_path_for(resource)
    root_path   # 例：後で dashboard_path などに変更
  end
  def after_sign_out_path_for(resource_or_scope)
    root_path
  end
  
  def basic_auth_applicable?
    Rails.env.production? &&
      ENV["BASIC_AUTH_USER"].present? &&
      ENV["BASIC_AUTH_PASSWORD"].present? &&
      request.path != "/up" # ヘルスチェックは除外
  end

  def basic_auth
    authenticate_or_request_with_http_basic("Restricted") do |user, pass|
      ActiveSupport::SecurityUtils.secure_compare(user.to_s,  ENV.fetch("BASIC_AUTH_USER")) &&
      ActiveSupport::SecurityUtils.secure_compare(pass.to_s,  ENV.fetch("BASIC_AUTH_PASSWORD"))
    end
  end
end