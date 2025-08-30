class AddUniqueIndexToRewardUnlocks < ActiveRecord::Migration[7.1]
  # PG の並行インデックス作成ではトランザクション外が必要
  disable_ddl_transaction!

  INDEX_NAME = "index_reward_unlocks_on_child_and_reward_unique"

  def change
    add_index :reward_unlocks, [:child_id, :reward_id],
              unique: true,
              name: "index_reward_unlocks_on_child_and_reward_unique"
  end
  
  def up
    adapter = ActiveRecord::Base.connection.adapter_name.downcase

    # 1) 既存の重複データを削除（最小IDを残して他を消す）
    case adapter
    when /postgres/
      execute <<~SQL
        DELETE FROM reward_unlocks ru
        USING reward_unlocks keep
        WHERE ru.child_id = keep.child_id
          AND ru.reward_id = keep.reward_id
          AND ru.id > keep.id;
      SQL
    else
      # SQLite 等：Rubyで汎用的に削除
      rows = execute <<~SQL
        SELECT child_id, reward_id, MIN(id) AS keep_id, COUNT(*) AS cnt
        FROM reward_unlocks
        GROUP BY child_id, reward_id
        HAVING COUNT(*) > 1;
      SQL
      rows.each do |r|
        child_id  = r["child_id"]
        reward_id = r["reward_id"]
        keep_id   = r["keep_id"]
        execute <<~SQL
          DELETE FROM reward_unlocks
          WHERE child_id = #{child_id}
            AND reward_id = #{reward_id}
            AND id <> #{keep_id};
        SQL
      end
    end

    # 2) 複合ユニークインデックスを追加
    if adapter.match?(/postgres/)
      add_index :reward_unlocks, [:child_id, :reward_id],
                unique: true,
                name: INDEX_NAME,
                algorithm: :concurrently
    else
      add_index :reward_unlocks, [:child_id, :reward_id],
                unique: true,
                name: INDEX_NAME
    end
  end

  def down
    remove_index :reward_unlocks, name: INDEX_NAME
  end
end