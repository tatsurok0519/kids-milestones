class BackfillMedalAndTrophyRewards < ActiveRecord::Migration[7.1]
  MEDALS = [
    { tier: "bronze", threshold: 5,  icon_path: "icons/medal_bronze.png" },
    { tier: "silver", threshold: 10, icon_path: "icons/medal_silver.png" },
    { tier: "gold",   threshold: 20, icon_path: "icons/medal_gold.png"   },
  ].freeze

  TROPHIES = [
    # ファイル名はプロジェクトの実ファイルに合わせて調整可
    { tier: "bronze", threshold: 30, icon_path: "icons/trophy-bronze.png" },
    { tier: "silver", threshold: 40, icon_path: "icons/trophy_silver.png" },
    { tier: "gold",   threshold: 50, icon_path: "icons/trophy_gold.png"   },
  ].freeze

  def up
    # 念のためユニーク制約（既にあればスキップ）。インデックス名は問わず列の組み合わせで判定
    unless index_exists?(:rewards, %i[kind tier], unique: true)
      add_index :rewards, %i[kind tier], unique: true
    end

    say_with_time "upsert medals (5/10/20)" do
      MEDALS.each { |row| sql_upsert_reward!("medal", row[:tier], row[:threshold], row[:icon_path]) }
    end

    say_with_time "upsert trophies (30/40/50)" do
      TROPHIES.each { |row| sql_upsert_reward!("trophy", row[:tier], row[:threshold], row[:icon_path]) }
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "安全のためロールバック不可"
  end

  private

  # モデル非依存の SQL upsert（バリデーション完全回避）
  def sql_upsert_reward!(kind, tier, threshold, icon_path)
    has_icon = column_exists?(:rewards, :icon_path)

    insert_cols = %w[kind tier threshold created_at updated_at]
    insert_cols.insert(3, "icon_path") if has_icon

    values_sql = [
      quote(kind),
      quote(tier),
      quote(threshold),
    ]
    values_sql.insert(3, quote(icon_path)) if has_icon
    values_sql << "CURRENT_TIMESTAMP" << "CURRENT_TIMESTAMP"

    update_set = ["threshold = EXCLUDED.threshold", "updated_at = CURRENT_TIMESTAMP"]
    update_set.insert(1, "icon_path = EXCLUDED.icon_path") if has_icon

    execute <<~SQL.squish
      INSERT INTO rewards (#{insert_cols.join(', ')})
      VALUES (#{values_sql.join(', ')})
      ON CONFLICT (kind, tier) DO UPDATE
        SET #{update_set.join(', ')};
    SQL
  end
end