class AddUniqueIndexOnRewardsKindAndTier < ActiveRecord::Migration[7.1]
  def change
    add_index :rewards, [:kind, :tier], unique: true unless index_exists?(:rewards, [:kind, :tier], unique: true)
  end
end