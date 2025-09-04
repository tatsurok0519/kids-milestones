require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "unauthenticated root should be reachable" do
    get unauthenticated_root_url
    assert_response :success
  end

  test "authenticated root should be reachable after sign in" do
    user = User.create!(name: "テスター", email: "tester@example.com", password: "password123")
    sign_in user
    get authenticated_root_url
    assert_response :success
  end
end