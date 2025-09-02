require "application_system_test_case"

class GuestTasksFlowTest < ApplicationSystemTestCase
  test "guest can view tasks list" do
    visit tasks_path
    assert_text "できるかな"      # 見出し
    # 代表的なカード要素が出ていること（文言はあなたのUIに合わせて）
    assert_selector ".card", minimum: 1
  end
end