class RewardUnlocker
  def self.call(child)
    new(child).call
  end

  def initialize(child)
    @child = child
  end

  def call
    return unless @child
    count = @child.achievements.where(achieved: true).count

    # しきい値を満たした報酬をまとめて解放（既存はスキップ）
    Reward.where("threshold <= ?", count).find_each do |rw|
      RewardUnlock.find_or_create_by(child: @child, reward: rw) do |unlock|
        unlock.unlocked_at = Time.current
      end
    end

    # 累計ごほうびなので「取り消し」はしません（仕様）
  end
end