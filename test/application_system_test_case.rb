# test/application_system_test_case.rb
require "test_helper"
require "capybara/rails"
require "capybara/minitest"

# Chrome が無い環境でも動く安全ドライバを用意
Capybara.register_driver :headless_chrome_safe do |app|
  require "selenium/webdriver"
  opts = Selenium::WebDriver::Chrome::Options.new
  opts.add_argument("--headless=new")
  opts.add_argument("--disable-gpu")
  opts.add_argument("--no-sandbox")
  # （必要なら）Chrome の実行ファイルパスを環境変数で指定
  if ENV["CHROME_BINARY"].to_s != ""
    opts.binary = ENV["CHROME_BINARY"]
  end
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: opts)
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driver = ENV["SYSTEM_TEST_DRIVER"] # 明示指定があればそれを優先

  if driver == "rack_test"
    driven_by :rack_test
  else
    begin
      driven_by :headless_chrome_safe, screen_size: [1400, 1400]
    rescue Selenium::WebDriver::Error::WebDriverError, Webdrivers::BrowserNotFound
      warn "[system test] Chrome not found. Falling back to :rack_test"
      driven_by :rack_test
    end
  end
end