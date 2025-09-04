require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(name: "テスター", email: "tester@example.com", password: "password123")
  end

  test "should get show when signed in" do
    sign_in @user
    get dashboard_url
    assert_response :success
  end
end