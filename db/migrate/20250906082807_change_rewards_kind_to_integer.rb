class ChangeRewardsKindToInteger < ActiveRecord::Migration[7.1]
  def up
    adapter = ActiveRecord::Base.connection.adapter_name.downcase

    if adapter.include?("sqlite")
      # 途中失敗に強くするため、まずFKをOFF
      execute "PRAGMA foreign_keys = OFF"

      # 途中失敗で rewards_old が残っている場合：データ移行は済んでいる想定なので
      # インデックスだけ保証して、old は消す or リネームして抜ける
      if ActiveRecord::Base.connection.data_source_exists?("rewards_old")
        # 同名インデックスが old に残っている可能性があるので、先に落としてから作成
        execute "DROP INDEX IF EXISTS index_rewards_on_kind_and_tier"
        execute "CREATE UNIQUE INDEX IF NOT EXISTS index_rewards_on_kind_and_tier ON rewards(kind, tier)"
        begin
          execute "DROP TABLE rewards_old"
        rescue ActiveRecord::StatementInvalid
          # DROPできない環境でも詰まらないよう、退避名にリネームして逃がす
          execute "ALTER TABLE rewards_old RENAME TO rewards_legacy_#{Time.now.to_i}"
        end
        execute "PRAGMA foreign_keys = ON"
        return
      end

      # ここから通常パス：新テーブルを整数kindで作成
      execute <<~SQL
        CREATE TABLE rewards_new (
          id          INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          kind        INTEGER NOT NULL DEFAULT 0,
          tier        VARCHAR NOT NULL,
          threshold   INTEGER NOT NULL,
          icon_path   VARCHAR NOT NULL,
          created_at  DATETIME NOT NULL,
          updated_at  DATETIME NOT NULL
        );
      SQL

      # 旧rewards(kindがstring or NULL)から新へコピー
      # kindがNULLでも icon_path / threshold から推定して正しい整数へ詰め替える
      execute <<~SQL
        INSERT INTO rewards_new (id, kind, tier, threshold, icon_path, created_at, updated_at)
        SELECT
          id,
          CASE
            WHEN kind IN ('medal','0') THEN 0
            WHEN kind IN ('trophy','1') THEN 1
            WHEN kind IN ('special','2') THEN 2
            WHEN icon_path LIKE 'icons/trophy_%' OR threshold IN (30,40,50) THEN 1
            WHEN icon_path LIKE 'icons/medal_%'  OR threshold IN (5,10,20)  THEN 0
            WHEN icon_path LIKE '%crown%' OR icon_path LIKE '%decoration%' OR icon_path LIKE '%hall_of_fame%' OR threshold IN (65,80,100) THEN 2
            ELSE 0
          END AS kind,
          tier, threshold, icon_path, created_at, updated_at
        FROM rewards;
      SQL

      # 旧→oldに退避、新→本番名へ
      execute "ALTER TABLE rewards RENAME TO rewards_old;"
      execute "ALTER TABLE rewards_new RENAME TO rewards;"

      # インデックスを新テーブルに必ず付ける（先に同名を落としてから）
      execute "DROP INDEX IF EXISTS index_rewards_on_kind_and_tier"
      execute "CREATE UNIQUE INDEX IF NOT EXISTS index_rewards_on_kind_and_tier ON rewards(kind, tier);"

      # oldを削除。ダメならリネーム退避で進める
      begin
        execute "DROP TABLE rewards_old;"
      rescue ActiveRecord::StatementInvalid
        execute "ALTER TABLE rewards_old RENAME TO rewards_legacy_#{Time.now.to_i};"
      end

      execute "PRAGMA foreign_keys = ON"
    else
      # SQLite以外（参考実装）
      add_column :rewards, :kind_i, :integer, null: false, default: 0 unless column_exists?(:rewards, :kind_i)
      execute <<~SQL
        UPDATE rewards
           SET kind_i = CASE
             WHEN kind IN ('medal','0') THEN 0
             WHEN kind IN ('trophy','1') THEN 1
             WHEN kind IN ('special','2') THEN 2
             ELSE 0
           END
      SQL
      remove_column :rewards, :kind, :string if column_exists?(:rewards, :kind)
      rename_column :rewards, :kind_i, :kind if column_exists?(:rewards, :kind_i)
      add_index :rewards, [:kind, :tier], unique: true, name: "index_rewards_on_kind_and_tier" unless index_exists?(:rewards, [:kind, :tier], name: "index_rewards_on_kind_and_tier", unique: true)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end