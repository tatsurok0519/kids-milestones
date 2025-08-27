require "rails_helper"

RSpec.describe Child, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:achievements).dependent(:destroy) }
    it { is_expected.to have_many(:milestones).through(:achievements) }
    it { is_expected.to have_one_attached(:photo) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:birthday) }

    it "許可された画像形式ならOK" do
      child = build(:child)
      child.photo.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/test.jpg")),
        filename: "test.jpg",
        content_type: "image/jpeg"
      )
      expect(child).to be_valid
    end

    it "不正な形式ならエラー" do
      child = build(:child)
      child.photo.attach(
        io: StringIO.new("fake"),
        filename: "fake.txt",
        content_type: "text/plain"
      )
      expect(child).to be_invalid
      expect(child.errors[:photo].join).to include("画像を選んでください").or include("画像")
    end

    it "5MB超ならエラー（sizeバリデーション相当）" do
      child = build(:child)
      child.photo.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/test.jpg")),
        filename: "test.jpg",
        content_type: "image/jpeg"
      )
      # blob のサイズを強制スタブ（実ファイルを巨大化しなくてOK）
      child.valid?
      allow(child.photo.blob).to receive(:byte_size).and_return(6.megabytes)
      child.validate
      expect(child.errors[:photo].join).to include("5MB")
    end
  end

  describe "#age_years_and_months / #age_label" do
    it "年齢の配列とラベルが返る" do
      child = build(:child, birthday: Date.today << 14) # 14ヶ月前
      y, m = child.age_years_and_months
      expect(y * 12 + m).to be_within(1).of(14) # ざっくり月齢を確認
      expect(child.age_label).to match(/歳|か月/)
    end
  end

  describe "variants" do
    it "photo_thumb / photo_card が返る（添付時）" do
      # build ではなく create で保存済みにする
      child = create(:child)

      child.photo.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/test.jpg")),
        filename: "test.jpg",
        content_type: "image/jpeg"
      )

      # 念のためリロードして、添付が反映されていることを確認
      child.reload
      expect(child.photo).to be_attached

      # ここで実際に variant を生成（例外が出ないことを確認）
      expect { child.photo_thumb }.not_to raise_error
      expect { child.photo_card  }.not_to raise_error
    end
  end
end