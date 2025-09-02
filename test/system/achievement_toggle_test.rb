require "application_system_test_case"

class AchievementToggleTest < ApplicationSystemTestCase
  include UiHelpers

  setup do
    @user  = User.create!(email: "u@example.com", password: "password", name: "親")
    @child = Child.create!(user: @user, name: "りょうや", birthday: Date.new(2020,1,1))
    @ms    = Milestone.create!(title: "ボールを蹴る", category: "運動", difficulty: 1, min_months: 24, max_months: 35)
  end

  test "pressing できた！ toggles state via turbo (no full page reload)" do
    # rack_test（＝JSなし）ならこのテストはスキップ
    if Capybara.current_driver == :rack_test
      skip "JS driver not available on this machine"
    end

    login_as_via_ui(email: "u@example.com", password: "password")

    visit tasks_path(age_band: "all")
    frame_id = ActionView::RecordIdentifier.dom_id(@ms, :controls)

    within("##{frame_id}") { click_button "できた！" }
    within("##{frame_id}") { assert_selector "button.btn.btn-primary.is-active", text: "できた！" }

    within("##{frame_id}") { click_button "できた！" }
    within("##{frame_id}") { assert_no_selector "button.btn.btn-primary.is-active" }
  end
end