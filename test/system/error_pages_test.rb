require "application_system_test_case"

class ErrorPagesTest < ApplicationSystemTestCase
  test "404 page shows brand-styled guidance" do
    visit "/definitely-no-page"
    assert_text "ページが見つかりません"
    assert_selector ".btn", text: "前のページに戻る"
  end

  test "403 page shows access denied" do
    visit "/403"
    assert_text "アクセスできません"
  end
end