class RewardUnlock < ApplicationRecord
  belongs_to :child
  belongs_to :reward
  validates :unlocked_at, presence: true
end