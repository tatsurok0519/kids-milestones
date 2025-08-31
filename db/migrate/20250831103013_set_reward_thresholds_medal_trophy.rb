class SetRewardThresholdsMedalTrophy < ActiveRecord::Migration[7.1]
  # 正解テーブル（メダル：5/10/20、トロフィー：30/40/50）
  TARGETS = {
    "medal"  => { 1 => 5,  2 => 10, 3 => 20 }, # 銅/銀/金
    "trophy" => { 1 => 30, 2 => 40, 3 => 50 }, # 銅/銀/金
  }.freeze

  def up
    TARGETS.each do |kind, tiers|
      tiers.each do |tier, threshold|
        execute <<~SQL.squish
          UPDATE rewards
             SET threshold = #{threshold}, updated_at = CURRENT_TIMESTAMP
           WHERE kind = #{ActiveRecord::Base.connection.quote(kind)}
             AND tier = #{tier}
        SQL
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "元のしきい値に戻す情報を持ちません"
  end
end