class RewardUnlocker
  def self.call(child)
    new(child).call
  end

  def initialize(child)
    @child = child
  end

  # 戻り値: 今回「新たに」解放された Reward の配列（なければ []）
  def call
    return [] unless @child

    # 累計の「できた！」数（取り消しはあっても、ごほうびは累計扱い）
    achieved_count = @child.achievements.where(achieved: true).count

    # しきい値を満たしたごほうび候補（並びは閾値→ID）
    eligible_scope = Reward.where("threshold <= ?", achieved_count).order(:threshold, :id)
    eligible_ids    = eligible_scope.pluck(:id)
    return [] if eligible_ids.empty?

    # 事前に「すでに解放済み」のIDを取っておく（今回の“新規”判定に使う）
    before_ids = RewardUnlock.where(child_id: @child.id).pluck(:reward_id)

    # 今回作る対象（＝候補 − 既存）
    target_ids = eligible_ids - before_ids
    return [] if target_ids.empty?

    now = Time.current
    rows = target_ids.map do |rid|
      # unlocked_at カラムが無い場合は migration か下行を削ってください
      { child_id: @child.id, reward_id: rid, unlocked_at: now, created_at: now, updated_at: now }
    end

    # できるだけ一括で保存（DB/環境に応じて安全にフォールバック）
    if RewardUnlock.respond_to?(:upsert_all)
      begin
        # PG ではユニークインデックス名を使うと堅い。SQLite 開発環境ではカラム配列でOK。
        unique_by =
          if ActiveRecord::Base.connection.adapter_name.downcase.include?("postgres")
            :index_reward_unlocks_on_child_and_reward_unique # ← マイグレーションで付けた名前に合わせる
          else
            %i[child_id reward_id]
          end

        RewardUnlock.upsert_all(rows, unique_by: unique_by)
      rescue => _
        # upsert_all が失敗したら行ごとに安全に作成（同時実行は rescue で吸収）
        create_one_by_one!(target_ids, now)
      end
    else
      # 古いRails等：行ごと
      create_one_by_one!(target_ids, now)
    end

    # 「今回新たに増えたもの」＝保存後の状態 − 保存前
    after_ids = RewardUnlock.where(child_id: @child.id, reward_id: eligible_ids).pluck(:reward_id)
    new_ids   = after_ids - before_ids
    return [] if new_ids.empty?

    Reward.where(id: new_ids).order(:threshold, :id).to_a
  end

  private

  def create_one_by_one!(reward_ids, timestamp)
    reward_ids.each do |rid|
      begin
        RewardUnlock.find_or_create_by!(child_id: @child.id, reward_id: rid) do |unlock|
          # unlocked_at カラムがある場合だけセット
          unlock.unlocked_at = timestamp if unlock.respond_to?(:unlocked_at)
        end
      rescue ActiveRecord::RecordNotUnique
        # 競合（他リクエストがほぼ同時に作成）→ 既存を使う/スキップでOK
      end
    end
  end
end