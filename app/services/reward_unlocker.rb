class RewardUnlocker
  # 返り値：今回「新たに」解放された Reward の配列（なければ []）
  def self.call(child) = new(child).call

  def initialize(child)
    @child   = child
    @adapter = ActiveRecord::Base.connection.adapter_name.downcase
  end

  def call
    return [] unless @child

    achieved_count = @child.achievements.where(achieved: true).count

    candidates = Reward
      .where(kind: %w[medal trophy special])
      .where("threshold <= ?", achieved_count)
      .order(:threshold, :id)

    ids     = candidates.pluck(:id)
    before  = RewardUnlock.where(child_id: @child.id, reward_id: ids).pluck(:reward_id)
    target  = ids - before

    # ← 追加：アンロック判定の中身を全部出す
    Rails.logger.info(
      "[unlocker] child=#{@child.id} count=#{achieved_count} " \
      "candidates=#{ids} before=#{before} target=#{target}"
    )

    return [] if target.blank?

    now   = Time.current
    rows  = target.map { |rid| { child_id: @child.id, reward_id: rid, unlocked_at: now, created_at: now, updated_at: now } }
    upsert_rows!(rows)

    newly = RewardUnlock.where(child_id: @child.id, reward_id: ids).pluck(:reward_id) - before
    return [] if newly.blank?

    Reward.where(id: newly).order(:threshold, :id).to_a
  end

  private

  def upsert_rows!(rows)
    if RewardUnlock.respond_to?(:upsert_all)
      unique_by = @adapter.include?("postgres") ?
        :index_reward_unlocks_on_child_and_reward_unique : %i[child_id reward_id]
      RewardUnlock.upsert_all(rows, unique_by: unique_by)
    else
      rows.each do |attrs|
        begin
          RewardUnlock.find_or_create_by!(child_id: attrs[:child_id], reward_id: attrs[:reward_id]) do |ru|
            ru.assign_attributes(attrs.except(:child_id, :reward_id))
          end
        rescue ActiveRecord::RecordNotUnique
          # 同時実行の競合は既存優先で無視
        end
      end
    end
  end

  def column_exists?(table, column)
    ActiveRecord::Base.connection.column_exists?(table, column)
  end
end