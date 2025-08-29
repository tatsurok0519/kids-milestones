class CreateRewardUnlocks < ActiveRecord::Migration[7.1]
  def change
    create_table :reward_unlocks do |t|
      t.references :child,  null: false, foreign_key: true
      t.references :reward, null: false, foreign_key: true
      t.datetime   :unlocked_at, null: false
      t.timestamps
    end
    add_index :reward_unlocks, [:child_id, :reward_id], unique: true
  end
end