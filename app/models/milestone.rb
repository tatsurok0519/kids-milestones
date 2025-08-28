class Milestone < ApplicationRecord
  # 関連
  has_many :achievements, dependent: :destroy

  # ===== スコープ =====

  # months が nil のときは全年齢対象
  scope :for_age, ->(months) {
    where("(min_months IS NULL OR min_months <= ?) AND (max_months IS NULL OR max_months >= ?)", months, months)
  }

  # 年齢帯（0..5）のインデックスに対し、帯とミッションの月齢レンジが「重なる」ものを返す
  scope :for_age_band, ->(band_index) {
    i = band_index.to_i.clamp(0, 5)
    min = i * 12; max = min + 11
    where("(min_months IS NULL OR min_months <= :max) AND (max_months IS NULL OR max_months >= :min)",
          min: min, max: max)
    .where.not(min_months: nil, max_months: nil)   # ← 追加
  }

  # カテゴリ・難易度フィルタ
  scope :by_category,   ->(cat) { cat.present? ? where(category: cat) : all }
  scope :by_difficulty, ->(dif) { dif.present? ? where(difficulty: dif) : all }

  # 未達成のみ（指定 child で achieved=true になっていないタスク）
  scope :unachieved_for, ->(child) {
    if child.present?
      where.not(id: child.achievements.where(achieved: true).select(:milestone_id))
    else
      all
    end
  }

  # ===== バリデーション =====
  validates :difficulty, inclusion: { in: 1..3 }

  # ===== 表示ヘルパ =====

  # 個別ヒント優先。description があればそれを返し、無い場合はカテゴリ×難易度の定型を返す
  def hint_text
    return description if description.present?

    base =
      case category.to_s
      when "運動"
        "安全第一。足元を片づけ、転びにくい環境で短時間から。"
      when "言語"
        "大人がゆっくりお手本。まねっこ遊びと繰り返しのやり取りが効果的。"
      when "手先"
        "机と椅子の高さを合わせ、材料は少なくシンプルに始める。"
      when "生活"
        "手順を小分けにして一つずつ成功を重ねていく。"
      when "認知"
        "見本→一緒に→一人での順に段階化。正解を視覚で示すと理解が進む。"
      when "社会性"
        "簡単なルールと役割から。出来たらすぐ共感と称賛で習慣化。"
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