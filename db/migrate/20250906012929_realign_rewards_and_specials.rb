class RealignRewardsAndSpecials < ActiveRecord::Migration[7.1]
  MEDAL_THRESHOLDS  = { "bronze" => 5,  "silver" => 10, "gold" => 20 }.freeze
  TROPHY_THRESHOLDS = { "bronze" => 30, "silver" => 40, "gold" => 50 }.freeze

  # 既存のデータ方針（kind='special', tier に 'crown' 等を入れる）を踏襲
  SPECIALS = [
    { tier: "crown",        threshold: 65,  icon_path: "icons/crown.png" },
    { tier: "decoration",   threshold: 80,  icon_path: "icons/decoration.png" },
    { tier: "hall_of_fame", threshold: 100, icon_path: "icons/hall_of_fame.png" },
  ].freeze

  TIER_MAP_NUM_TO_NAME = { "1" => "bronze", "2" => "silver", "3" => "gold" }.freeze

  def up
    say_with_time "normalize rewards.tier 1/2/3 -> bronze/silver/gold (medal/trophy only)" do
      TIER_MAP_NUM_TO_NAME.each do |from, to|
        execute <<~SQL.squish
          UPDATE rewards
             SET tier = #{quote(to)}, updated_at = CURRENT_TIMESTAMP
           WHERE tier = #{quote(from)}
             AND kind IN ('medal','trophy')
        SQL
      end
    end

    say_with_time "set medal thresholds to 5/10/20" do
      MEDAL_THRESHOLDS.each do |tier, th|
        execute <<~SQL.squish
          UPDATE rewards
             SET threshold = #{quote(th)}, updated_at = CURRENT_TIMESTAMP
           WHERE kind = 'medal' AND tier = #{quote(tier)}
        SQL
      end
    end

    say_with_time "set trophy thresholds to 30/40/50" do
      TROPHY_THRESHOLDS.each do |tier, th|
        execute <<~SQL.squish
          UPDATE rewards
             SET threshold = #{quote(th)}, updated_at = CURRENT_TIMESTAMP
           WHERE kind = 'trophy' AND tier = #{quote(tier)}
        SQL
      end
    end

    # === ここが A 案：モデル非依存の SQL upsert（検証回避） ===
    say_with_time "upsert special rewards (crown/decoration/hall_of_fame)" do
      specials_have_icon = column_exists?(:rewards, :icon_path)

      SPECIALS.each do |row|
        # 挿入カラム集合を動的に（icon_path が無ければ含めない）
        insert_cols = %w[kind tier threshold created_at updated_at]
        insert_cols.insert(3, "icon_path") if specials_have_icon

        values_sql = [
          quote("special"),
          quote(row[:tier]),
          quote(row[:threshold]),
        ]
        values_sql.insert(3, quote(row[:icon_path])) if specials_have_icon
        values_sql << "CURRENT_TIMESTAMP" << "CURRENT_TIMESTAMP"

        # 更新セット（icon_path があればそれも更新）
        update_set = ["threshold = EXCLUDED.threshold", "updated_at = CURRENT_TIMESTAMP"]
        update_set.insert(1, "icon_path = EXCLUDED.icon_path") if specials_have_icon

        execute <<~SQL.squish
          INSERT INTO rewards (#{insert_cols.join(', ')})
          VALUES (#{values_sql.join(', ')})
          ON CONFLICT (kind, tier) DO UPDATE
            SET #{update_set.join(', ')};
        SQL
      end
    end

    # 既にユニークインデックスがあれば追加しない（名前は問わず列で判定）
    unless index_exists?(:rewards, %i[kind tier], unique: true)
      add_index :rewards, %i[kind tier], unique: true
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "安全のためロールバック不可"
  end
end