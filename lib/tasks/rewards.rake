namespace :rewards do
  desc "花丸数から RewardUnlock を作成/補完（全子ども）"
  task rebuild_unlocks: :environment do
    Child.find_each do |child|
      Reward.unlock_for!(child)
    end
    puts "done."
  end
end