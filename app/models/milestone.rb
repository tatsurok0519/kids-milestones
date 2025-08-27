class Milestone < ApplicationRecord
  # months が nil のときは全年齢対象
  scope :for_age, ->(months) {
    where("(min_months IS NULL OR min_months <= ?) AND (max_months IS NULL OR max_months >= ?)", months, months)
  }
  validates :difficulty, inclusion: { in: 1..3 }

  # 年齢帯（0..5）のインデックスに対し、帯とミッションの月齢レンジが「重なる」ものを返す
  scope :for_age_band, ->(band_index) {
    i   = band_index.to_i.clamp(0, 5)
    min = i * 12
    max = min + 11
    where(
      "(min_months IS NULL OR min_months <= :band_max) AND (max_months IS NULL OR max_months >= :band_min)",
      band_min: min, band_max: max
    )
  }
end