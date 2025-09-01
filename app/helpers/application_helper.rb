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

  # 静的画像（app/assets/images/*）に lazy/async を常時付与
  def asset_img(name, width:, height:, **opts)
    image_tag name, { width: width, height: height, loading: "lazy", decoding: "async" }.merge(opts)
  end

  # ActiveStorage添付を安全に（欠損に強い） + 明示サイズ
  # 例) attachment_img(child.photo, variant: child.photo_thumb, width:80, height:80)
  def attachment_img(attachment, variant:, width:, height:, **opts)
    return "" unless attachment&.attached?
    begin
      image_tag variant, { width: width, height: height, loading: "lazy", decoding: "async" }.merge(opts)
    rescue ActiveStorage::FileNotFoundError
      asset_img("illustrations/sun.png", width:, height:, **opts)
    end
  end

  # 画像タグを安全＆軽量に（lazy/async/寸法付き）
  def asset_img(path, alt: "", width: nil, height: nil, **opts)
    opts[:loading]  ||= "lazy"
    opts[:decoding] ||= "async"
    opts[:width]    ||= width if width
    opts[:height]   ||= height if height
    image_tag(path, { alt: alt }.merge(opts))
  end
end