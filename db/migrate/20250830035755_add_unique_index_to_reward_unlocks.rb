class AddUniqueIndexToRewardUnlocks < ActiveRecord::Migration[7.1]
  # PostgreSQL の並行作成に対応
  disable_ddl_transaction!

  INDEX_NAME = "index_reward_unlocks_on_child_and_reward_unique"
  COLUMNS    = [:child_id, :reward_id]

  def up
    # 既に目的の一意インデックスがあれば何もしない
    if unique_index_exists_for?(:reward_unlocks, COLUMNS, INDEX_NAME)
      return
    end

    # 重複データを除去（最古の1件だけ残す）
    cleanup_duplicates!

    # 既存の非ユニークindex（同名/同列）を外す
    if index_exists?(:reward_unlocks, COLUMNS, name: INDEX_NAME)
      remove_index :reward_unlocks, name: INDEX_NAME, **rm_opts
    elsif index_exists?(:reward_unlocks, COLUMNS)
      remove_index :reward_unlocks, column: COLUMNS, **rm_opts
    end

    # 一意インデックスを作成
    add_index :reward_unlocks, COLUMNS, unique: true, name: INDEX_NAME, **add_opts
  end

  def down
    remove_index :reward_unlocks, name: INDEX_NAME if index_exists?(:reward_unlocks, name: INDEX_NAME)
    # 必要なら非ユニークindexに戻す
    add_index :reward_unlocks, COLUMNS, name: INDEX_NAME, **rm_opts unless index_exists?(:reward_unlocks, name: INDEX_NAME)
  end

  private

  def add_opts
    postgresql? ? { algorithm: :concurrently } : {}
  end

  def rm_opts
    postgresql? ? { algorithm: :concurrently } : {}
  end

  def postgresql?
    ActiveRecord::Base.connection.adapter_name.downcase.include?("postgres")
  end

  def unique_index_exists_for?(table, columns, _name)
    cols_sorted = columns.map(&:to_s).sort
    ActiveRecord::Base.connection.indexes(table).any? { |idx| idx.unique && idx.columns.sort == cols_sorted }
  end

  # (child_id, reward_id) の重複を除去して最古の1件だけ残す
  def cleanup_duplicates!
    if postgresql?
      execute <<~SQL
        WITH dups AS (
          SELECT child_id, reward_id, MIN(id) AS keep_id
          FROM reward_unlocks
          GROUP BY child_id, reward_id
          HAVING COUNT(*) > 1
        )
        DELETE FROM reward_unlocks ru
        USING dups
        WHERE ru.child_id = dups.child_id
          AND ru.reward_id = dups.reward_id
          AND ru.id <> dups.keep_id;
      SQL
    else
      rows = ActiveRecord::Base.connection.exec_query(<<~SQL)
        SELECT child_id, reward_id, MIN(id) AS keep_id, COUNT(*) AS cnt
        FROM reward_unlocks
        GROUP BY child_id, reward_id
        HAVING COUNT(*) > 1;
      SQL
      rows.each do |r|
        child_id  = r["child_id"].to_i
        reward_id = r["reward_id"].to_i
        keep_id   = r["keep_id"].to_i
        ActiveRecord::Base.connection.execute <<~SQL
          DELETE FROM reward_unlocks
          WHERE child_id = #{child_id}
            AND reward_id = #{reward_id}
            AND id <> #{keep_id};
        SQL
      end
    end
  end
end