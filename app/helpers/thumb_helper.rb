# frozen_string_literal: true

module ThumbHelper
  # 子ども写真の正方形サムネール（安全版）
  # 加工はせず attachment_img に任せる（欠損時はプレースホルダ表示）
  def child_thumb(child, size: 80, alt: nil)
    alt ||= child&.respond_to?(:name) ? child.name.to_s : "photo"
    attachment_img(child&.photo, alt:, width: size, height: size)
  end
end