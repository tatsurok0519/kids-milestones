require "test_helper"

class ChildrenControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user  = User.create!(name: "テスター", email: "tester@example.com", password: "password123")
    @child = @user.children.create!(name: "たろう", birthday: Date.new(2020,1,1))
  end

  test "should get index when signed in" do
    sign_in @user
    get children_url
    assert_response :success
  end

  test "should get new when signed in" do
    sign_in @user
    get new_child_url
    assert_response :success
  end

  test "show redirects to index (by design)" do
    sign_in @user
    get child_url(@child)
    assert_redirected_to children_url
  end

  test "should get edit when signed in" do
    sign_in @user
    get edit_child_url(@child)
    assert_response :success
  end
end