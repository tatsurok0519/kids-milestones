class AddAgeRangeToMilestones < ActiveRecord::Migration[7.1]
  def change
    add_column :milestones, :min_months, :integer
    add_column :milestones, :max_months, :integer
  end
end
