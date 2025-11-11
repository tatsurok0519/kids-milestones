module ApplicationHelper
  # サインインユーザーの表示名
  def display_user_name
    return "ゲスト" unless user_signed_in?
    if current_user.respond_to?(:name) && current_user.name.present?
      current_user.name
    else
      current_user.email.to_s.split("@").first
    end
  end

  # 花丸数
  def hanamaru_count(child)
    return 0 unless child
    Achievement.where(child_id: child.id, achieved: true).count
  end

  # milestones.hint_text カラム有無（メモ化）
  def milestones_has_hint_text_column?
    return @__has_hint_text unless @__has_hint_text.nil?
    @__has_hint_text = Milestone.column_names.include?("hint_text")
  rescue
    @__has_hint_text = false
  end

  # ---- 画像ヘルパ ---------------------------------------------------------

  def asset_img(path, alt: "", width: nil, height: nil, lazy: true, fetch: nil, **opts)
    opts[:loading]       ||= (lazy ? "lazy" : "eager")
    opts[:decoding]      ||= "async"
    opts[:fetchpriority] ||= fetch if fetch
    opts[:width]         ||= width if width
    opts[:height]        ||= height if height
    image_tag(path, { alt: alt }.merge(opts))
  end

  def safe_blob_image_tag(variant_or_attachable, alt: "", width: nil, height: nil, lazy: true, fetch: nil, **opts)
    return "" if variant_or_attachable.blank?
    opts[:loading]       ||= (lazy ? "lazy" : "eager")
    opts[:decoding]      ||= "async"
    opts[:fetchpriority] ||= fetch if fetch
    opts[:width]         ||= width if width
    opts[:height]        ||= height if height
    image_tag(variant_or_attachable, { alt: alt }.merge(opts))
  rescue ActiveStorage::FileNotFoundError, ActiveStorage::IntegrityError, ArgumentError
    ""
  end

  def attachment_img(attachment, variant: nil, alt: "", width: nil, height: nil,
                     placeholder: "illustrations/sun.png", lazy: true, fetch: nil, **opts)
    unless attachment&.attached?
      return asset_img(placeholder, alt:, width:, height:, lazy:, fetch:, **opts)
    end

    # Cloudinary を検知したら即フォールバック（ダウンロード/変換をさせない）
    service_name = attachment.try(:blob)&.service_name.to_s
    if service_name.downcase.include?("cloudinary")
      return asset_img(placeholder, alt:, width:, height:, lazy:, fetch:, **opts)
    end

    target = variant || attachment
    safe_blob_image_tag(target, alt:, width:, height:, lazy:, fetch:, **opts).presence ||
      asset_img(placeholder, alt:, width:, height:, lazy:, fetch:, **opts)
  rescue => e
    Rails.logger.warn("[attachment_img] fallback due to #{e.class}: #{e.message}")
    asset_img(placeholder, alt:, width:, height:, lazy:, fetch:, **opts)
  end
end