require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'factory_bot_rails'
require 'devise'
require 'shoulda/matchers'

# Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # 単数！ fixture_path（fixture_paths ではない）
  config.fixture_paths = [Rails.root.join('spec/fixtures')]

  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # ===== ここがポイント：この中に入れる =====
  # FactoryBotの省略形（create/build など）
  config.include FactoryBot::Syntax::Methods

  # Devise / Warden ヘルパー
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Warden::Test::Helpers, type: :system
  config.after(type: :system) { Warden.test_reset! }

  # ActiveJob（purge_later 検証用）
  require 'active_job'
  ActiveJob::Base.queue_adapter = :test
  # ==========================================
end

# Shoulda Matchers の統合設定（RSpec.configure の外）
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
