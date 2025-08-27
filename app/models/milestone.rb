class Milestone < ApplicationRecord
  # months が nil のときは全年齢対象
  scope :for_age, ->(months) {
    where("(min_months IS NULL OR min_months <= ?) AND (max_months IS NULL OR max_months >= ?)", months, months)
  }

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

  # ▼ 追加：カテゴリ・難易度フィルタ
  scope :by_category,   ->(cat) { cat.present? ? where(category: cat) : all }
  scope :by_difficulty, ->(dif) { dif.present? ? where(difficulty: dif) : all }

  # ▼ 既存仕様に合わせて 1..3 を許可
  validates :difficulty, inclusion: { in: 1..3 }

  # ===== 表示ヘルパ =====

  # ★を返す（例: 難易度2 → "★★"）
  def difficulty_stars
    "★" * difficulty.to_i.clamp(1, 3)
  end

  # このタスクが該当する年齢帯ラベル（例: "0–1歳 / 1–2歳"）
  def age_band_labels
    bands = age_band_indices
    return "-" if bands.empty?
    bands.map { |i| "#{i}–#{i + 1}歳" }.join(" / ")
  end

  private

  # min_months..max_months を 0..5 の帯にマッピング
  def age_band_indices
    min = (min_months || 0)
    max = (max_months || 71) # 0..71か月 = 0–6歳
    min_i = (min / 12).clamp(0, 5)
    max_i = (max / 12).clamp(0, 5)
    (min_i..max_i).to_a
  end
end