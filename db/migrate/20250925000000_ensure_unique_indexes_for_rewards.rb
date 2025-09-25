class EnsureUniqueIndexesForRewards < ActiveRecord::Migration[7.1]
  # Postgres 用に DDL トランザクションを無効化（SQLite/他でも害はない）
  disable_ddl_transaction!

  INDEX_RW  = "index_rewards_on_kind_and_tier_unique"
  INDEX_RWU = "index_reward_unlocks_on_child_and_reward_unique"

  def up
    add_rewards_index
    add_reward_unlocks_index
  end

  def down
    remove_index(:rewards,        name: INDEX_RW)  if index_name_exists_any?(:rewards, INDEX_RW)
    remove_index(:reward_unlocks, name: INDEX_RWU) if index_name_exists_any?(:reward_unlocks, INDEX_RWU)
  end

  private

  def postgres?
    connection.adapter_name.to_s.downcase.include?("postgres")
  end

  def sqlite?
    connection.adapter_name.to_s.downcase.include?("sqlite")
  end

  # --- ここがポイント：SQLite では sqlite_master を直接見る -----------------
  def index_name_exists_any?(table, name)
    if sqlite?
      sql = "SELECT name FROM sqlite_master WHERE type='index' AND name = #{connection.quote(name)}"
      connection.exec_query(sql).rows.any?
    else
      index_name_exists?(table, name)
    end
  end

  # 失敗しても「同名 index が実在する」ならそのまま続行
  def safe_add_index(table, columns, **opts)
    # 先に本当に存在しないかを SQLite 互換で再確認
    return if index_name_exists_any?(table, opts[:name])

    add_index(table, columns, **opts)
  rescue ActiveRecord::StatementInvalid
    # エラーになっても、実体があれば OK とみなして握りつぶす
    raise unless index_name_exists_any?(table, opts[:name])
  end

  def add_rewards_index
    return if index_name_exists_any?(:rewards, INDEX_RW)

    opts = { unique: true, name: INDEX_RW }
    opts[:algorithm] = :concurrently if postgres?
    safe_add_index(:rewards, %i[kind tier], **opts)
  end

  def add_reward_unlocks_index
    return if index_name_exists_any?(:reward_unlocks, INDEX_RWU)

    opts = { unique: true, name: INDEX_RWU }
    opts[:algorithm] = :concurrently if postgres?
    safe_add_index(:reward_unlocks, %i[child_id reward_id], **opts)
  end
end