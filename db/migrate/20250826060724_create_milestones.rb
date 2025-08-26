class CreateMilestones < ActiveRecord::Migration[7.1]
  def change
    create_table :milestones do |t|
      t.string  :title,      null: false
      t.string  :category,   null: false
      t.integer :difficulty, null: false, default: 1
      t.text    :description
      t.timestamps

      # ← インデックスは create_table ブロック内で
      t.index :category
      t.index :difficulty
    end
  end
end