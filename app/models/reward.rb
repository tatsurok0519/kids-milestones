class Reward < ApplicationRecord
  # DBには 0/1/2 の整数で保存
  enum kind: { medal: 0, trophy: 1, special: 2 }

  has_many :reward_unlocks, dependent: :destroy

  validates :kind,      presence: true
  validates :tier,      presence: true
  validates :threshold, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :icon_path, presence: true
  validates :tier, uniqueness: { scope: :kind } # 種別×段位で一意

  # 並び順（← 文字列ではなく「整数 0/1/2」を比較）
  scope :ordered, -> {
    order(Arel.sql("CASE kind WHEN 0 THEN 0 WHEN 1 THEN 1 ELSE 2 END"), :threshold, :id)
  }

  # 既存ユーザの不足Unlockを補完
  def self.unlock_for!(child)
    return 0 unless child
    achieved_count =
      if child.respond_to?(:achievements)
        child.achievements.where(achieved: true).count
      else
        Achievement.where(child_id: child.id, achieved: true).count
      end

    new_ids = Reward.where("threshold <= ?", achieved_count).pluck(:id) -
              RewardUnlock.where(child_id: child.id).pluck(:reward_id)

    now = Time.current
    rows = new_ids.map { |rid| { child_id: child.id, reward_id: rid, unlocked_at: now, created_at: now, updated_at: now } }
    RewardUnlock.insert_all(rows) if rows.any?
    new_ids.size
  end
end