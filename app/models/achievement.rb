class Achievement < ApplicationRecord
  belongs_to :child
  belongs_to :milestone

  validates :child_id, :milestone_id, presence: true

  # ※ ここで RewardUnlocker.call(child) を呼ばない
  #    （after_commit / after_save などのコールバックも置かない）
end