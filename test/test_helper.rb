ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # ここに共通ユーティリティを書いてOK
end

# System テストに UI ヘルパを読み込み
Dir[File.join(__dir__, "system/support/**/*.rb")].sort.each { |f| require f }