module ApplicationHelper
  def display_user_name
    return "ゲスト" unless user_signed_in?

    if current_user.respond_to?(:name) && current_user.name.present?
      current_user.name
    else
      # nameカラムが無い/未入力なら、メールの@前を仮の表示名に
      current_user.email.to_s.split("@").first
    end
  end
end