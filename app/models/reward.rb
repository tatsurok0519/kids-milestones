class Reward < ApplicationRecord
  enum kind: { medal: "medal", trophy: "trophy" }
  enum tier: { bronze: "bronze", silver: "silver", gold: "gold" }

  has_many :reward_unlocks, dependent: :destroy

  validates :kind, :tier, :threshold, :icon_path, presence: true
  validates :threshold, numericality: { only_integer: true, greater_than: 0 }
end