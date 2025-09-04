ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # fixtures :all  # フィクスチャを使うなら有効化
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end