module ChildrenHelper
  def child_photo_tag(child, **opts)
    return image_tag("illustrations/sun.png", alt: "", **opts) unless child&.photo&.attached?
    image_tag(child.photo_card, **opts)
  rescue => e
    Rails.logger.warn("[photo] variant failed: #{e.class}: #{e.message}")
    image_tag(child.photo, **opts)
  end
end