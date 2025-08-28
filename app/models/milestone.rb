class Milestone < ApplicationRecord
  # 関連（あると便利）
  has_many :achievements, dependent: :destroy

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

  # ▼ 追加：未達成のみ（指定の child で「achieved=true」が付いていないタスク）
  scope :unachieved_for, ->(child) {
    if child.present?
      where.not(id: child.achievements.where(achieved: true).select(:milestone_id))
    else
      all
    end
  }

  # ▼ 既存仕様に合わせて 1..3 を許可
  validates :difficulty, inclusion: { in: 1..3 }

  def hint_text
    base =
      case category.to_s
      when /運動|体|歩|走|ジャンプ/
        "安全第一。足元を片づけ、転びにくい環境で短時間から。"
      when /ことば|言葉|語|読|話|音/
        "大人がゆっくりお手本。まねっこ遊びや繰り返しが効果的です。"
      when /手先|指|つみき|工作|描|握|巧緻/
        "机の高さを合わせ、材料は少なくシンプルに始めましょう。"
      when /生活|身支度|食事|トイレ|習慣/
        "手順を小分けにして一つずつ成功を重ねるのが近道です。"
      else
        "うまくいかない日は休憩OK。成功しやすい環境づくりがコツ。"
      end

    step =
      case difficulty.to_i
      when 1 then "まずは一緒にやってコツをつかもう。小さな達成で自信づけ。"
      when 2 then "前回できた所から半歩アップ。無理せず繰り返し。"
      else         "目標をさらに細かく分けてOK。今日は一歩だけ前へ。"
      end

    "#{base} #{step}"
  end

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