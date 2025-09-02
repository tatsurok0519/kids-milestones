module UiHelpers
  def login_as_via_ui(email:, password:)
    visit new_user_session_path
    fill_in "メールアドレス", with: email rescue fill_in "Email", with: email
    fill_in "パスワード", with: password rescue fill_in "Password", with: password
    click_button "ログイン" rescue click_button "Log in"
  end
end