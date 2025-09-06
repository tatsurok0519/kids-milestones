class BackfillAndDefaultUnlockedAtOnRewardUnlocks < ActiveRecord::Migration[7.1]
  def up
    # 既存の NULL を現在時刻で埋める
    execute <<~SQL.squish
      UPDATE reward_unlocks
         SET unlocked_at = CURRENT_TIMESTAMP
       WHERE unlocked_at IS NULL
    SQL

    # 以後のデフォルトを付ける（SQLite/MySQL/PostgreSQL いずれも CURRENT_TIMESTAMP でOK）
    change_column_default :reward_unlocks, :unlocked_at, -> { "CURRENT_TIMESTAMP" }

    # NOT NULL を担保（既に付いていれば no-op）
    change_column_null :reward_unlocks, :unlocked_at, false
  end

  def down
    change_column_null    :reward_unlocks, :unlocked_at, true
    change_column_default :reward_unlocks, :unlocked_at, nil
  end
end