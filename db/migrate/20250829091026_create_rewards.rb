class CreateRewards < ActiveRecord::Migration[7.1]
  def change
    create_table :rewards do |t|
      t.string  :kind,      null: false  # "medal" or "trophy"
      t.string  :tier,      null: false  # "bronze" "silver" "gold"
      t.integer :threshold, null: false  # 累計花丸のしきい値
      t.string  :icon_path, null: false # assetsのパス（例: icons/medal_bronze.png）
      t.timestamps
    end
    add_index :rewards, [:kind, :tier], unique: true
    add_index :rewards, :threshold
  end
end