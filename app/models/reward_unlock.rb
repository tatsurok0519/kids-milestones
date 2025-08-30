class RewardUnlock < ApplicationRecord
  belongs_to :child
  belongs_to :reward

  validates :unlocked_at, presence: true
  validates :reward_id, uniqueness: { scope: :child_id }  # 複合一意
  validates :child_id,  presence: true
  validates :reward_id, presence: true
end