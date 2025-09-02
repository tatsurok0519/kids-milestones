require "application_system_test_case"

class ReportPageTest < ApplicationSystemTestCase
  include UiHelpers

  setup do
    @user  = User.create!(email: "u2@example.com", password: "password", name: "親")
    @child = Child.create!(user: @user, name: "ゆき", birthday: Date.new(2021,5,5))
  end

  test "open child report and see print button" do
    login_as_via_ui(email: "u2@example.com", password: "password")
    visit child_report_path(@child)
    assert_text "ふりかえりレポート"
    assert_button "印刷する"
  end
end