class RewardUnlocker
  # 返り値: 今回「新たに」解放された Reward の配列（なければ []）
  def self.call(child)
    new(child).call
  end

  def initialize(child)
    @child = child
    @adapter = ActiveRecord::Base.connection.adapter_name.downcase
  end

  def call
    return [] unless @child

    # 現在の「できた！」数（通算ではなく現在値）
    achieved_count = @child.achievements.where(achieved: true).count

    # しきい値を満たした候補（メダル／トロフィー想定。別種も閾値連動なら追加可）
    candidates = Reward
      .where(kind: %w[medal trophy])
      .where("threshold <= ?", achieved_count)
      .order(:threshold, :id)

    candidate_ids = candidates.pluck(:id)
    return [] if candidate_ids.empty?

    # 既に解放済みのID
    before_ids = RewardUnlock.where(child_id: @child.id, reward_id: candidate_ids).pluck(:reward_id)

    # 今回作る対象
    target_ids = candidate_ids - before_ids
    return [] if target_ids.empty?

    now = Time.current
    rows = target_ids.map do |rid|
      h = { child_id: @child.id, reward_id: rid, created_at: now, updated_at: now }
      h[:unlocked_at] = now if column_exists?(:reward_unlocks, :unlocked_at)
      h
    end

    upsert_rows!(rows)

    # 保存後に増えたIDを差分で取得
    after_ids = RewardUnlock.where(child_id: @child.id, reward_id: candidate_ids).pluck(:reward_id)
    new_ids   = after_ids - before_ids
    return [] if new_ids.empty?

    Reward.where(id: new_ids).order(:threshold, :id).to_a
  end

  private

  def upsert_rows!(rows)
    if RewardUnlock.respond_to?(:upsert_all)
      unique_by =
        if @adapter.include?("postgres")
          # マイグレーションで付けた一意インデックス名
          :index_reward_unlocks_on_child_and_reward_unique
        else
          %i[child_id reward_id]
        end
      RewardUnlock.upsert_all(rows, unique_by: unique_by)
    else
      rows.each do |attrs|
        begin
          RewardUnlock.find_or_create_by!(child_id: attrs[:child_id], reward_id: attrs[:reward_id]) do |ru|
            ru.assign_attributes(attrs.except(:child_id, :reward_id))
          end
        rescue ActiveRecord::RecordNotUnique
          # 同時実行の競合は無視（既存を優先）
        end
      end
    end
  rescue => _
    # upsert_all 非対応や一時的失敗時のフォールバック（1行ずつ）
    rows.each do |attrs|
      begin
        RewardUnlock.find_or_create_by!(child_id: attrs[:child_id], reward_id: attrs[:reward_id]) do |ru|
          ru.assign_attributes(attrs.except(:child_id, :reward_id))
        end
      rescue ActiveRecord::RecordNotUnique
      end
    end
  end

  def column_exists?(table, column)
    ActiveRecord::Base.connection.column_exists?(table, column)
  end
end