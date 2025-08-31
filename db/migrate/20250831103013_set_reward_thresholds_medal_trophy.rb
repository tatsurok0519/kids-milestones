class SetRewardThresholdsMedalTrophy < ActiveRecord::Migration[7.1]
  TARGETS = {
    "medal"  => { 1 => 5,  2 => 10, 3 => 20 }, # 銅/銀/金
    "trophy" => { 1 => 30, 2 => 40, 3 => 50 }, # 銅/銀/金
  }.freeze

  def up
    conn = ActiveRecord::Base.connection

    TARGETS.each do |kind, tiers|
      tiers.each do |tier, threshold|
        # ★ tier は本番で varchar なので、文字列として比較（quote で安全に）
        conn.execute <<~SQL.squish
          UPDATE rewards
             SET threshold = #{threshold}, updated_at = CURRENT_TIMESTAMP
           WHERE kind = #{conn.quote(kind)}
             AND tier = #{conn.quote(tier.to_s)}
        SQL
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "元のしきい値に戻す情報を持ちません"
  end
end