require "rails_helper"

RSpec.describe Achievement, type: :model do
  subject(:achievement) { build(:achievement) }

  describe "関連" do
    it "child に必須の belongs_to を持つ" do
      is_expected.to belong_to(:child).required
    end

    it "milestone に必須の belongs_to を持つ" do
      is_expected.to belong_to(:milestone).required
    end
  end

  describe "バリデーション" do
    it "child 単位で milestone_id が重複しない（日本語メッセージを許容）" do
      create(:achievement) # 既存レコードが必要
      is_expected
        .to validate_uniqueness_of(:milestone_id)
        .scoped_to(:child_id)
        .with_message(/(既に|すでに|重複|達成)/)
    end

    it "同じ child/milestone の重複はバリデーションで弾く（日本語メッセージを許容）" do
      a1  = create(:achievement)
      dup = build(:achievement, child: a1.child, milestone: a1.milestone)

      expect(dup).to be_invalid
      expect(dup.errors[:milestone_id].join).to match(/既に|すでに|重複|達成/)
    end

    it "デフォルト値は working=false, achieved=false, achieved_at=nil である" do
      a = build(:achievement)
      expect(a.working).to eq(false)
      expect(a.achieved).to eq(false)
      expect(a.achieved_at).to be_nil
    end
  end

  describe "データベースの一意制約（存在すれば確認）" do
    it "複合ユニークインデックス [:child_id, :milestone_id] により重複が防止される" do
      indexes = ActiveRecord::Base.connection.indexes(:achievements)
      has_unique_index = indexes.any? { |idx| idx.unique && idx.columns.sort == %w[child_id milestone_id] }

      skip "複合ユニークインデックスが未設定のためスキップ" unless has_unique_index

      c = create(:child)
      m = create(:milestone)
      create(:achievement, child: c, milestone: m)

      expect {
        described_class.insert_all!([{
          child_id: c.id,
          milestone_id: m.id,
          working: false,
          achieved: false,
          achieved_at: nil,
          created_at: Time.current,
          updated_at: Time.current
        }])
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end