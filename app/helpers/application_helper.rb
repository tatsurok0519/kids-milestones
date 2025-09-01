module ApplicationHelper
  def display_user_name
    return "ゲスト" unless user_signed_in?
    current_user.respond_to?(:name) && current_user.name.present? ?
      current_user.name : current_user.email.to_s.split("@").first
  end

  # milestones.hint_text カラムの有無を一度だけ判定してメモ化
  def milestones_has_hint_text_column?
    return @__has_hint_text unless @__has_hint_text.nil?
    @__has_hint_text = Milestone.column_names.include?('hint_text')
  rescue
    @__has_hint_text = false
  end
end