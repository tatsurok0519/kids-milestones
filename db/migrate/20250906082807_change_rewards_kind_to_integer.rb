class ChangeRewardsKindToInteger < ActiveRecord::Migration[7.1]
  def up
    # 1) 旧 kind(文字列/文字列数字) → kind_i(整数) へコピー
    add_column :rewards, :kind_i, :integer, null: false, default: 0
    execute <<~SQL
      UPDATE rewards
         SET kind_i = CASE kind
           WHEN 'medal'   THEN 0
           WHEN 'trophy'  THEN 1
           WHEN 'special' THEN 2
           WHEN '0' THEN 0 WHEN '1' THEN 1 WHEN '2' THEN 2
           ELSE 0
         END;
    SQL

    # 2) 既存 index を “名前指定” で確実に削除（どちらがある環境でもOK）
    %i[index_rewards_on_kind_and_tier index_rewards_on_kind_and_tier_unique].each do |idx|
      remove_index :rewards, name: idx, if_exists: true
    end

    # 3) 旧 kind を落として kind_i を kind にリネーム
    remove_column :rewards, :kind, :string
    rename_column :rewards, :kind_i, :kind

    # 4) (kind,tier) の重複行を整理
    #    - 最小 id を正とし reward_unlocks のFKを付け替え（既存があればスキップ）
    execute <<~SQL
      WITH kept AS (
        SELECT MIN(id) AS keep_id, kind, tier
          FROM rewards
         GROUP BY kind, tier
      ),
      dup AS (
        SELECT r.id AS dup_id, r.kind, r.tier, k.keep_id
          FROM rewards r
          JOIN kept k ON k.kind = r.kind AND k.tier = r.tier
         WHERE r.id <> k.keep_id
      )
      UPDATE reward_unlocks ru
         SET reward_id = d.keep_id
        FROM dup d
       WHERE ru.reward_id = d.dup_id
         AND NOT EXISTS (
               SELECT 1 FROM reward_unlocks ru2
                WHERE ru2.child_id = ru.child_id
                  AND ru2.reward_id = d.keep_id
             );
    SQL

    #    - reward_unlocks の重複( child_id, reward_id ) を1行に圧縮
    execute <<~SQL
      DELETE FROM reward_unlocks ru
       USING (
         SELECT MIN(id) AS keep_id, child_id, reward_id
           FROM reward_unlocks
          GROUP BY child_id, reward_id
       ) k
       WHERE ru.child_id = k.child_id
         AND ru.reward_id = k.reward_id
         AND ru.id <> k.keep_id;
    SQL

    #    - 重複 reward 行のダブりを削除
    execute <<~SQL
      DELETE FROM rewards r
       USING (
         SELECT r2.id
           FROM rewards r2
           JOIN (
                 SELECT MIN(id) AS keep_id, kind, tier
                   FROM rewards
                  GROUP BY kind, tier
                ) k
             ON k.kind = r2.kind AND k.tier = r2.tier
          WHERE r2.id <> k.keep_id
       ) d
       WHERE r.id = d.id;
    SQL

    # 5) ユニーク index を作成（本命）
    add_index :rewards, [:kind, :tier], unique: true, name: "index_rewards_on_kind_and_tier"
  end

  def down
    remove_index :rewards, name: "index_rewards_on_kind_and_tier", if_exists: true
    add_column :rewards, :kind_s, :string
    execute <<~SQL
      UPDATE rewards
         SET kind_s = CASE kind
           WHEN 0 THEN 'medal'
           WHEN 1 THEN 'trophy'
           ELSE 'special'
         END;
    SQL
    remove_column :rewards, :kind
    rename_column :rewards, :kind_s, :kind
    add_index :rewards, [:kind, :tier], unique: true, name: "index_rewards_on_kind_and_tier", if_not_exists: true
  end
end