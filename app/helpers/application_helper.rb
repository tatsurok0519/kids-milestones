# frozen_string_literal: true

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

  # 花丸数（達成済みカウント）
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

  # 静的アセット用（/app/assets/images/*）
  # lazy/async/寸法をデフォルト付与。必要に応じて fetchpriority も。
  #
  # 例) asset_img("illustrations/sun.png", width: 24, height: 24)
  def asset_img(path, alt: "", width: nil, height: nil, lazy: true, fetch: nil, **opts)
    opts[:loading]       ||= (lazy ? "lazy" : "eager")
    opts[:decoding]      ||= "async"
    opts[:fetchpriority] ||= fetch if fetch
    opts[:width]         ||= width if width
    opts[:height]        ||= height if height
    image_tag(path, { alt: alt }.merge(opts))
  end

  # ActiveStorage の添付/バリアントを安全に表示（例外時は空文字）
  #
  # 例) safe_blob_image_tag(child.photo, alt: "...", width: 80, height: 80)
  def safe_blob_image_tag(variant_or_attachable, alt: "", width: nil, height: nil, lazy: true, fetch: nil, **opts)
    return "" if variant_or_attachable.blank?
    opts[:loading]       ||= (lazy ? "lazy" : "eager")
    opts[:decoding]      ||= "async"
    opts[:fetchpriority] ||= fetch if fetch
    opts[:width]         ||= width if width
    opts[:height]        ||= height if height
    image_tag(variant_or_attachable, { alt: alt }.merge(opts))
  rescue ActiveStorage::FileNotFoundError,
         ActiveStorage::IntegrityError,
         ArgumentError,
         URI::InvalidURIError
    "" # 画面を落とさず無視
  end

  # ActiveStorage 添付を “プレースホルダ付き” で表示。
  # - 添付なし/欠損時はプレースホルダにフォールバック。
  # - variant を渡せばそちらを優先（thumb/card など）
  #
  # 例)
  #   attachment_img(child.photo, variant: child.photo_thumb, alt:"...", width:80, height:80)
  def attachment_img(attachment, variant: nil, alt: "", width: nil, height: nil,
                     placeholder: "illustrations/sun.png", lazy: true, fetch: nil, **opts)
    unless attachment&.attached?
      return asset_img(placeholder, alt:, width:, height:, lazy:, fetch:, **opts)
    end

    # ここでは加工は行わず、指定があれば variant、そのままなら attachment を表示
    target = variant || attachment
    safe_blob_image_tag(target, alt:, width:, height:, lazy:, fetch:, **opts).presence ||
      asset_img(placeholder, alt:, width:, height:, lazy:, fetch:, **opts)
  rescue => e
    Rails.logger.warn("[attachment_img] fallback due to #{e.class}: #{e.message}")
    asset_img(placeholder, alt:, width:, height:, lazy:, fetch:, **opts)
  end

  # --- Cloudinary 簡易 cl_image_tag ---------------------------------------
  # Cloudinary gemがなくても <img> を出せる簡易版。
  # CLOUDINARY_CLOUD_NAME もしくは CLOUDINARY_URL から cloud_name を取得して、
  # 変換(w,h,crop)を最小限サポート。
  #
  # 例: cl_image_tag("icons/check", width: 64, height: 64, alt: "OK", format: "png")
  def cl_image_tag(public_id, alt: "", format: "png", **opts)
    return "".html_safe if public_id.blank?

    cloud_name = resolve_cloudinary_cloud_name
    if cloud_name.present?
      # 変換パラメータ（w/h/crop）の簡易対応
      trans = []
      trans << "w_#{opts.delete(:width)}"  if opts[:width]
      trans << "h_#{opts.delete(:height)}" if opts[:height]
      trans << "c_#{opts.delete(:crop)}"   if opts[:crop]
      trans_path = trans.any? ? "#{trans.join(',')}/" : ""

      fmt = (format.presence || "png").to_s
      src = "https://res.cloudinary.com/#{cloud_name}/image/upload/#{trans_path}#{ERB::Util.url_encode(public_id)}.#{fmt}"
      return image_tag(src, { alt: alt }.merge(opts))
    end

    # Cloudinary設定がなければプレースホルダへ退避
    asset_img("illustrations/sun.png", alt:, **opts)
  rescue => e
    Rails.logger.warn("[cl_image_tag] fallback due to #{e.class}: #{e.message}")
    asset_img("illustrations/sun.png", alt:, **opts)
  end

  # cloudinary_js_config は空でOK（使っていなければ無害）
  def cloudinary_js_config(*) = "".html_safe

  private

  # CLOUDINARY_CLOUD_NAME or CLOUDINARY_URL から cloud_name を解決
  def resolve_cloudinary_cloud_name
    return ENV["CLOUDINARY_CLOUD_NAME"] if ENV["CLOUDINARY_CLOUD_NAME"].present?

    url = ENV["CLOUDINARY_URL"].to_s
    return if url.empty?

    # cloudinary://key:secret@cloud_name[/...]
    at_pos = url.rindex("@")
    return if at_pos.nil?

    rest = url[(at_pos + 1)..-1]
    rest.split(/[\/?\s]/).first # cloud_name を抽出
  rescue
    nil
  end
end