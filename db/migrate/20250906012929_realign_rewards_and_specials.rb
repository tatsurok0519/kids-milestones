class RealignRewardsAndSpecials < ActiveRecord::Migration[7.1]
  MEDAL_THRESHOLDS  = { "bronze" => 5,  "silver" => 10, "gold" => 20 }.freeze
  TROPHY_THRESHOLDS = { "bronze" => 30, "silver" => 40, "gold" => 50 }.freeze
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

    # special を必ず用意（冪等）
    say_with_time "upsert special rewards (crown/decoration/hall_of_fame)" do
      Reward.reset_column_information
      SPECIALS.each do |row|
        r = Reward.find_or_initialize_by(kind: "special", tier: row[:tier])
        r.threshold = row[:threshold]
        r.icon_path = row[:icon_path]
        r.save!
      end
    end

    # 重複防止の一意制約（既にあればスキップ）
    add_index :rewards, %i[kind tier], unique: true,
              name: "index_rewards_on_kind_and_tier_unique" \
              unless index_exists?(:rewards, %i[kind tier], unique: true,
                                  name: "index_rewards_on_kind_and_tier_unique")
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "安全のためロールバック不可"
  end
end