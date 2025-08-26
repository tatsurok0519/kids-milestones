class CreateAchievements < ActiveRecord::Migration[7.1]
  def change
    create_table :achievements do |t|
      t.references :child,     null: false, foreign_key: true
      t.references :milestone, null: false, foreign_key: true
      t.boolean :achieved, null: false, default: false
      t.boolean :working,  null: false, default: false
      t.datetime :achieved_at
      t.timestamps
    end
    add_index :achievements, [:child_id, :milestone_id], unique: true
  end
end