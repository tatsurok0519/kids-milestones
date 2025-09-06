class SwapTrophyBronzeIcon < ActiveRecord::Migration[7.1]
  def up
    # 本番: kind は integer enum（trophy = 1）
    execute <<~SQL
      UPDATE rewards
         SET icon_path = 'icons/trophy_bronze_v2.png'
       WHERE
             icon_path = 'icons/trophy_bronze.png'
          OR (tier = 'bronze' AND icon_path LIKE 'icons/trophy_bronze%')
          OR (kind = 1 AND tier = 'bronze');
    SQL
  end

  def down
    execute <<~SQL
      UPDATE rewards
         SET icon_path = 'icons/trophy_bronze.png'
       WHERE icon_path = 'icons/trophy_bronze_v2.png';
    SQL
  end
end