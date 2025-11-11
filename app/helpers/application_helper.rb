module ApplicationHelper
  # --- 基本ユーティリティ -------------------------------------------------

  # サインインユーザーの表示名
  def display_user_name
    return "ゲスト" unless user_signed_in?
    if current_user.respond_to?(:name) && current_user.name.present?
      current_user.name
    else
      current_user.email.to_s.split("@").first
    end
  end

  # メイン等で使う花丸数
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

  # --- Cloudinary ヘルパのダミー（テンプレ内に残っていても 500 を出さない） ----
  def cl_image_tag(*)         = "".html_safe
  def cloudinary_js_config(*) = "".html_safe
  def cl_image_path(*)        = ""

  # --- 画像ヘルパ（パフォーマンス最適化 & 安全化） -----------------------

  # 静的画像（app/assets/images/*）用：
  # lazy/async/寸法をデフォルト付与。必要に応じて fetchpriority も。
  #
  # 例) asset_img("illustrations/sun.png", width:24, height:24, style:"...")
  def asset_img(path, alt: "", width: nil, height: nil, lazy: true, fetch: nil, **opts)
    opts[:loading]       ||= (lazy ? "lazy" : "eager")
    opts[:decoding]      ||= "async"
    opts[:fetchpriority] ||= fetch if fetch
    opts[:width]         ||= width if width
    opts[:height]        ||= height if height
    image_tag(path, { alt: alt }.merge(opts))
  end

  # ActiveStorage の添付/バリアントを “安全に” 表示。
  # 欠損（実体なし）でも例外で画面を落とさず、空文字を返す。
  #
  # 例) safe_blob_image_tag(child.photo.variant(resize_to_fill:[80,80]).processed, alt:"...", width:80, height:80)
  def safe_blob_image_tag(variant_or_attachable, alt: "", width: nil, height: nil, lazy: true, fetch: nil, **opts)
    return "" if variant_or_attachable.blank?
    opts[:loading]       ||= (lazy ? "lazy" : "eager")
    opts[:decoding]      ||= "async"
    opts[:fetchpriority] ||= fetch if fetch
    opts[:width]         ||= width if width
    opts[:height]        ||= height if height
    image_tag(variant_or_attachable, { alt: alt }.merge(opts))
  rescue ActiveStorage::FileNotFoundError, ActiveStorage::IntegrityError, ArgumentError
    "" # 画面を落とさず無視
  end

  # ActiveStorage 添付を “プレースホルダ付き” で表示。
  # - 添付なし/欠損時はプレースホルダ（既定：sun）にフォールバック。
  # - variant は以下のいずれでも可：
  #     * ハッシュ（例: { resize_to_fill: [56,56] }）
  #     * ActiveStorage::Variant
  #     * nil（オリジナル）
  #
  # 例)
  #   attachment_img(child.photo, variant: child.photo_thumb, alt:"...", width:80, height:80)
  def attachment_img(attachment, variant: nil, alt: "", width: nil, height: nil,
                     placeholder: "illustrations/sun.png", lazy: true, fetch: nil, **opts)
    # 添付が無ければ即プレースホルダ
    unless attachment&.attached?
      return asset_img(placeholder, alt:, width:, height:, lazy:, fetch:, **opts)
    end

    # ★ 重要: Cloudinary 時代の blob を今のサービス(local 等)で処理しようとすると
    # ActiveStorage::IntegrityError になることがあるため “表示スキップ”
    begin
      current_service = ActiveStorage::Blob.service.name
      if attachment.blob.respond_to?(:service_name) &&
         attachment.blob.service_name != current_service
        return asset_img(placeholder, alt:, width:, height:, lazy:, fetch:, **opts)
      end
    rescue
      # 取得に失敗しても落とさない
    end

    # variant パラメータを解釈（Hash / Variant / nil のどれでもOK）
    target =
      case
      when variant.nil?
        attachment
      when defined?(ActiveStorage::Variant) &&
           (variant.is_a?(ActiveStorage::Variant) || variant.class.name.include?("Variant"))
        variant
      when variant.is_a?(Hash)
        # 変換は processed まで行っておく（URL生成時の例外を抑制）
        attachment.variant(**variant).processed
      else
        attachment # 想定外は原本で
      end

    # 実画像 or プレースホルダ
    safe_blob_image_tag(target, alt:, width:, height:, lazy:, fetch:, **opts).presence ||
      asset_img(placeholder, alt:, width:, height:, lazy:, fetch:, **opts)
  rescue ActiveStorage::FileNotFoundError, ActiveStorage::IntegrityError, ArgumentError
    asset_img(placeholder, alt:, width:, height:, lazy:, fetch:, **opts)
  end
end