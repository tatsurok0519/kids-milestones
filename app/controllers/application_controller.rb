class ApplicationController < ActionController::Base
  before_action :basic_auth, if: :basic_auth_applicable?
  before_action :authenticate_user! 

  private

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