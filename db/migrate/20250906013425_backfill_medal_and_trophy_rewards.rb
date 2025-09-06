class BackfillMedalAndTrophyRewards < ActiveRecord::Migration[7.1]
  MEDALS = [
    { tier: "bronze", threshold: 5,  icon_path: "icons/medal_bronze.png" },
    { tier: "silver", threshold: 10, icon_path: "icons/medal_silver.png" },
    { tier: "gold",   threshold: 20, icon_path: "icons/medal_gold.png"   },
  ].freeze

  TROPHIES = [
    # ※ ファイル名は手元の assets に合わせてください（下はあなたの seeds に寄せています）
    { tier: "bronze", threshold: 30, icon_path: "icons/trophy-bronze.png" },
    { tier: "silver", threshold: 40, icon_path: "icons/trophy_silver.png" },
    { tier: "gold",   threshold: 50, icon_path: "icons/trophy_gold.png"   },
  ].freeze

  def up
    Reward.reset_column_information

    say_with_time "upsert medals (5/10/20)" do
      MEDALS.each { |row| upsert_reward!(kind: :medal, **row) }
    end

    say_with_time "upsert trophies (30/40/50)" do
      TROPHIES.each { |row| upsert_reward!(kind: :trophy, **row) }
    end

    # 念のため一意制約（既にあればスキップ）
    add_index :rewards, %i[kind tier], unique: true,
              name: "index_rewards_on_kind_and_tier_unique" \
      unless index_exists?(:rewards, %i[kind tier], unique: true,
                           name: "index_rewards_on_kind_and_tier_unique")
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "安全のためロールバック不可"
  end

  private

  # enum/型差異に影響されにくい ActiveRecord 経由の upsert
  def upsert_reward!(kind:, tier:, threshold:, icon_path:)
    r = Reward.find_or_initialize_by(kind: kind, tier: tier)
    r.threshold = threshold
    r.icon_path = icon_path
    r.save!
  end
end