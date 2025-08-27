class AddUniqueIndexToAchievements < ActiveRecord::Migration[7.1]
  def change
    # 既存の非ユニークindexがあるなら外す（無ければ何もしない）
    if index_exists?(:achievements, [:child_id, :milestone_id], name: "index_achievements_on_child_id_and_milestone_id")
      remove_index :achievements, name: "index_achievements_on_child_id_and_milestone_id"
    elsif index_exists?(:achievements, [:child_id, :milestone_id])
      remove_index :achievements, column: [:child_id, :milestone_id]
    end

    # ユニークindexを貼る
    add_index :achievements, [:child_id, :milestone_id],
              unique: true,
              name: "index_achievements_on_child_id_and_milestone_id"
  end
end