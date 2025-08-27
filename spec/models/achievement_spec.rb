require "rails_helper"

RSpec.describe Achievement, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:child) }
    it { is_expected.to belong_to(:milestone) }
  end

  describe "uniqueness" do
    it "同じ child/milestone の重複はバリデーションで弾く" do
      a1  = create(:achievement)
      dup = build(:achievement, child: a1.child, milestone: a1.milestone)

      expect(dup).to be_invalid
      # ← 属性は milestone_id に付与される
      expect(dup.errors[:milestone_id].join).to match(/既に|すでに|重複|達成/)
    end
  end
end