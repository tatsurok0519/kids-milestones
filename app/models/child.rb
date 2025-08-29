class Child < ApplicationRecord
  belongs_to :user
  has_many :achievements, dependent: :destroy
  has_many :milestones, through: :achievements
  has_one_attached :photo, dependent: :purge_later
  has_many :reward_unlocks, dependent: :destroy
  has_many :rewards, through: :reward_unlocks

  validates :name, presence: true
  validates :birthday, presence: true

  validate :birthday_cannot_be_in_future

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

  # 0–6歳帯のインデックス（0..5）を返す
  # 例: 10ヶ月→0, 2歳3ヶ月→2, 7歳→5 に丸め（6歳以上は5-6歳帯に寄せる）
  def age_band_index
    m = age_in_months
    return 0 if m.nil?
    m = 0 if m < 0
    idx = m / 12
    idx > 5 ? 5 : idx
  end

  # UI表示用ラベル（"0–1歳" など）
  def age_band_label
    i = age_band_index
    "#{i}–#{i + 1}歳"
  end

  # その帯の月齢レンジ（例: 0→0..11, 2→24..35）
  def age_band_month_range
    i = age_band_index
    (i * 12)..(i * 12 + 11)
  end

  def achieved_count
    achievements.where(achieved: true).count
  end
  
  private
  def birthday_cannot_be_in_future
    return unless birthday.present?
    if birthday > Date.current
      errors.add(:birthday, "は今日以前を選んでください")
    end
  end

end