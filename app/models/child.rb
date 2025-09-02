class Child < ApplicationRecord
  belongs_to :user
  has_many :achievements, dependent: :destroy
  has_many :milestones, through: :achievements
  has_one_attached :photo, dependent: :purge_later
  has_many :reward_unlocks, dependent: :destroy
  has_many :rewards, through: :reward_unlocks

  validates :name, presence: true
  validates :birthday, presence: true
  validate  :birthday_cannot_be_in_future

  validate  :photo_must_be_image
  validate  :photo_size_limit

  # ==== 画像バリデーション ====
  def photo_must_be_image
    return unless photo.attached?
    unless photo.content_type.in?(%w[image/png image/jpeg image/jpg image/gif])
      errors.add(:photo, "はPNG/JPEG/GIFの画像を選んでください")
    end
  end

  def photo_size_limit
    return unless photo.attached?
    if photo.blob.byte_size > 5.megabytes
      errors.add(:photo, "は5MB以下にしてください")
    end
  end

  # ==== 画像ヘルパ（未保存や壊れた添付なら nil を返す）====
  # 80x80 サムネ（一覧/チップ用）
  def photo_thumb
    return unless photo.attached?
    photo.variant(resize_to_fill: [80, 80]).processed
  end

  # 400x300 カード用（ダッシュボード/タスク見出し）
  def photo_card
    return unless photo.attached?
    photo.variant(resize_to_fill: [400, 300]).processed
  end

  def safe_variant(w, h)
    # レコード未保存・未添付・非可変(HEIC等)は弾く
    return nil unless persisted?
    return nil unless photo.attached? && photo.variable?

    photo.variant(resize_to_fill: [w, h]).processed
  rescue ActiveStorage::FileNotFoundError, ArgumentError => e
    Rails.logger.warn("[Child#safe_variant] #{e.class}: #{e.message}")
    nil
  end

  # ==== 年齢系 ====
  def age_in_months
    return nil unless birthday
    years  = Date.current.year  - birthday.year
    months = Date.current.month - birthday.month
    months -= 1 if Date.current.day < birthday.day
    years * 12 + months
  end

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

  def age_band_index
    m = age_in_months
    return 0 if m.nil?
    m = 0 if m < 0
    idx = m / 12
    idx > 5 ? 5 : idx
  end

  def age_band_label
    i = age_band_index
    "#{i}–#{i + 1}歳"
  end

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