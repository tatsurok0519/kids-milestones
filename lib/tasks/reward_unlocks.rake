namespace :reward_unlocks do
  desc "既存の達成数から RewardUnlock を付与（不足分のみ作成）"
  task backfill: :environment do
    Child.find_each do |child|
      new_items = RewardUnlocker.call(child)
      puts "child #{child.id}: +#{new_items.size} unlocked"
    end
  end
end