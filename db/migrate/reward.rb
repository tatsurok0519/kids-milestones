class Reward < ApplicationRecord
  # special を追加
  enum kind: { medal: 0, trophy: 1, special: 2 }

  # 花丸(達成)の数に応じて不足している RewardUnlock を作成
  def self.unlock_for!(child)
    achieved_count =
      if child.respond_to?(:achievements)
        child.achievements.where(achieved: true).count
      else
        Achievement.where(child_id: child.id, achieved: true).count
      end

    Reward.where("threshold <= ?", achieved_count).find_each do |rw|
      RewardUnlock.find_or_create_by!(child_id: child.id, reward_id: rw.id)
    end
  end
end
