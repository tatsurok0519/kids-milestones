class ChangeRewardsKindToInteger < ActiveRecord::Migration[7.1]
  def up
    adapter = ActiveRecord::Base.connection.adapter_name.downcase

    if adapter.include?("sqlite")
      # --- SQLite: テーブル入れ替え ---
      execute "PRAGMA foreign_keys = OFF"

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

      execute "ALTER TABLE rewards RENAME TO rewards_old;"
      execute "ALTER TABLE rewards_new RENAME TO rewards;"
      execute "DROP INDEX IF EXISTS index_rewards_on_kind_and_tier"
      execute "CREATE UNIQUE INDEX IF NOT EXISTS index_rewards_on_kind_and_tier ON rewards(kind, tier);"
      # 旧テーブルは即 drop せず退避（外部キー都合）
      execute "ALTER TABLE rewards_old RENAME TO rewards_legacy_#{Time.now.to_i};"
      execute "PRAGMA foreign_keys = ON"
    else
      # --- PostgreSQL/MySQL: 一般的な手順 ---
      add_column :rewards, :kind_i, :integer, null: false, default: 0

      execute <<~SQL
        UPDATE rewards
           SET kind_i = CASE kind
             WHEN 'medal' THEN 0
             WHEN 'trophy' THEN 1
             WHEN 'special' THEN 2
             WHEN '0' THEN 0 WHEN '1' THEN 1 WHEN '2' THEN 2
             ELSE 0
           END;
      SQL

      remove_index :rewards, [:kind, :tier] rescue nil
      remove_column :rewards, :kind, :string
      rename_column :rewards, :kind_i, :kind
      add_index :rewards, [:kind, :tier], unique: true, name: "index_rewards_on_kind_and_tier"
    end
  end

  def down
    # ざっくり戻せるよう整数→文字列に戻す（最低限）
    adapter = ActiveRecord::Base.connection.adapter_name.downcase

    if adapter.include?("sqlite")
      execute "PRAGMA foreign_keys = OFF"
      execute <<~SQL
        CREATE TABLE rewards_new (
          id          INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          kind        VARCHAR NOT NULL,
          tier        VARCHAR NOT NULL,
          threshold   INTEGER NOT NULL,
          icon_path   VARCHAR NOT NULL,
          created_at  DATETIME NOT NULL,
          updated_at  DATETIME NOT NULL
        );
      SQL
      execute <<~SQL
        INSERT INTO rewards_new (id, kind, tier, threshold, icon_path, created_at, updated_at)
        SELECT id,
               CASE kind WHEN 0 THEN 'medal' WHEN 1 THEN 'trophy' ELSE 'special' END,
               tier, threshold, icon_path, created_at, updated_at
          FROM rewards;
      SQL
      execute "ALTER TABLE rewards RENAME TO rewards_old;"
      execute "ALTER TABLE rewards_new RENAME TO rewards;"
      execute "DROP INDEX IF EXISTS index_rewards_on_kind_and_tier"
      execute "CREATE UNIQUE INDEX IF NOT EXISTS index_rewards_on_kind_and_tier ON rewards(kind, tier);"
      execute "DROP TABLE rewards_old;"
      execute "PRAGMA foreign_keys = ON"
    else
      add_column    :rewards, :kind_s, :string, null: false, default: "medal"
      execute <<~SQL
        UPDATE rewards
           SET kind_s = CASE kind WHEN 0 THEN 'medal' WHEN 1 THEN 'trophy' ELSE 'special' END;
      SQL
      remove_index  :rewards, name: "index_rewards_on_kind_and_tier" rescue nil
      remove_column :rewards, :kind, :integer
      rename_column :rewards, :kind_s, :kind
      add_index     :rewards, [:kind, :tier], unique: true
    end
  end
end