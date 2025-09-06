class SwapTrophyBronzeIcon < ActiveRecord::Migration[7.1]
  def up
    # 旧パスを v2 に差し替え（idempotent）
    execute <<~SQL
      UPDATE rewards
         SET icon_path = 'icons/trophy_bronze_v2.png'
       WHERE icon_path = 'icons/trophy_bronze.png'
          OR ( (kind = 1 OR kind = 'trophy') AND tier = 'bronze' AND icon_path LIKE 'icons/trophy_bronze%');
    SQL
  end

  def down
    # もし元に戻す必要があれば
    execute <<~SQL
      UPDATE rewards
         SET icon_path = 'icons/trophy_bronze.png'
       WHERE icon_path = 'icons/trophy_bronze_v2.png';
    SQL
  end
end