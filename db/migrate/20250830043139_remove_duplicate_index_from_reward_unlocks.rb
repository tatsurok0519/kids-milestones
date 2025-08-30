class RemoveDuplicateIndexFromRewardUnlocks < ActiveRecord::Migration[7.1]
  def change
    remove_index :reward_unlocks, name: "index_reward_unlocks_on_child_id_and_reward_id"
  end
end