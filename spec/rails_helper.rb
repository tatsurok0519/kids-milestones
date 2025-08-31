# frozen_string_literal: true

require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "factory_bot_rails"
require "devise"
require "shoulda/matchers"

# spec/support 以下を自動読み込み（ヘルパ／マッチャ等）
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # ここを複数形に
  config.fixture_paths = [Rails.root.join("spec/fixtures")]

  # DBロールバック方式（SystemTest を JS で動かす場合は DatabaseCleaner 構成に切替も可）
  config.use_transactional_fixtures = true

  # spec/ ディレクトリ構成から自動で type を推定
  config.infer_spec_type_from_file_location!

  # Rails 由来の長いバックトレースを省略
  config.filter_rails_from_backtrace!

  # --- ここからテストで使う便利ヘルパ群 ---
  # FactoryBot の省略形（create/build 等）
  config.include FactoryBot::Syntax::Methods

  # Devise ヘルパ
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::ControllerHelpers,  type: :controller

  # Warden（主に System Test でのログイン補助）
  config.include Warden::Test::Helpers, type: :system
  config.after(type: :system) { Warden.test_reset! }

  # 時刻固定／時間移動（freeze_time / travel）
  config.include ActiveSupport::Testing::TimeHelpers

  # ActiveJob をテストアダプタに
  require "active_job"
  ActiveJob::Base.queue_adapter = :test

  # dom_id などをテスト内で使いたいときに便利
  config.include ActionView::RecordIdentifier
  # --- ここまで ---
end

# Shoulda Matchers の統合設定（RSpec.configure の外でOK）
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
