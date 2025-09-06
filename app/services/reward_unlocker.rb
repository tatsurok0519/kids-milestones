class RewardUnlocker
  def self.call(child) = new(child).call

  def initialize(child)
    @child   = child
    @adapter = ActiveRecord::Base.connection.adapter_name.downcase
  end

  def call
    return [] unless @child

    achieved_count = @child.achievements.where(achieved: true).count

    candidates = Reward
      .where(kind: %w[medal trophy special]) # ← special を含める
      .where("threshold <= ?", achieved_count)
      .order(:threshold, :id)

    ids = candidates.pluck(:id)
    return [] if ids.blank?

    before = RewardUnlock.where(child_id: @child.id, reward_id: ids).pluck(:reward_id)
    target = ids - before
    return [] if target.blank?

    now  = Time.current
    rows = target.map { |rid| { child_id: @child.id, reward_id: rid, created_at: now, updated_at: now } }
    upsert_rows!(rows)

    after = RewardUnlock.where(child_id: @child.id, reward_id: ids).pluck(:reward_id)
    newly = after - before
    return [] if newly.blank?

    Reward.where(id: newly).order(:threshold, :id).to_a
  end

  private

  def upsert_rows!(rows)
    if RewardUnlock.respond_to?(:upsert_all)
      unique_by = @adapter.include?("postgres") ? :index_reward_unlocks_on_child_and_reward_unique : %i[child_id reward_id]
      RewardUnlock.upsert_all(rows, unique_by: unique_by)
    else
      rows.each { |a| RewardUnlock.find_or_create_by!(child_id: a[:child_id], reward_id: a[:reward_id]) }
    end
  end
end