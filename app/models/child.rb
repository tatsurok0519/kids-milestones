class Child < ApplicationRecord
  belongs_to :user
  has_many :achievements, dependent: :destroy
  has_many :milestones, through: :achievements
  has_one_attached :photo, dependent: :purge_later

  validates :name, presence: true
  validates :birthday, presence: true

  validate :photo_must_be_image
  validate :photo_size_limit

  # 画像形式の軽いチェック（PNG/JPEG/GIF）
  def photo_must_be_image
    return unless photo.attached?
    unless photo.content_type.in?(%w[image/png image/jpeg image/jpg image/gif])
      errors.add(:photo, "はPNG/JPEG/GIFの画像を選んでください")
    end
  end

  # サイズ制限（例：5MB）
  def photo_size_limit
    return unless photo.attached?
    if photo.blob.byte_size > 5.megabytes
      errors.add(:photo, "は5MB以下にしてください")
    end
  end

  # ===== リサイズ用ヘルパ =====
  def photo_thumb
    return unless photo.attached?
    photo.variant(resize_to_fill: [80, 80]).processed
  end

  def photo_card
    return unless photo.attached?
    photo.variant(resize_to_fill: [400, 300]).processed
  end

  # 生後月齢（必要なら使用）
  def age_in_months
    return nil unless birthday
    years  = Date.current.year  - birthday.year
    months = Date.current.month - birthday.month
    months -= 1 if Date.current.day < birthday.day
    years * 12 + months
  end

  # 「◯歳◯か月」を返す（UI向け）
  def age_years_and_months
    return [nil, nil] unless birthday
    today  = Date.current
    years  = today.year  - birthday.year
    months = today.month - birthday.month
    months -= 1 if today.day < birthday.day
    if months < 0
      years  -= 1
      months += 12
    end
    [years, months]
  end
  alias_method :age_years_months, :age_years_and_months

  def age_label
    y, m = age_years_and_months
    return "" if y.nil?
    "#{y}歳#{m}か月"
  end
end