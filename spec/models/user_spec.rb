require "rails_helper"

RSpec.describe User, type: :model do
  let(:user) { build(:user) }

  context "新規登録できるとき" do
    it "name,email,password,password_confirmation が正しければ登録できる" do
      expect(user).to be_valid
    end
  end

  context "新規登録できないとき" do
    it "name が空では登録できない" do
      user.name = ""
      expect(user).to be_invalid
      expect(user.errors.added?(:name, :blank)).to be true
    end

    it "email が空では登録できない" do
      user.email = ""
      expect(user).to be_invalid
      expect(user.errors.added?(:email, :blank)).to be true
    end

    it "重複した email が存在する場合は登録できない" do
      create(:user, email: "test@example.com")
      dup = build(:user, email: "test@example.com")

      expect(dup).to be_invalid
      # ← シンボルではなく、emailにエラーが付いている事実を確認
      expect(dup.errors[:email]).to be_present
    end

    it "email は @ を含まないと登録できない" do
      user.email = "invalid_email"
      expect(user).to be_invalid
      expect(user.errors[:email]).to be_present
    end

    it "password が空では登録できない" do
      user.password = ""
      user.password_confirmation = ""
      expect(user).to be_invalid
      expect(user.errors.added?(:password, :blank)).to be true
    end

    it "password が7文字以下では登録できない（最小8）" do
      user.password = "a2b3c4d"      # 7文字
      user.password_confirmation = "a2b3c4d"
      expect(user).to be_invalid
      # too_short の最小値 8 を検証
      expect(user.errors.details[:password].any? { |e| e[:error] == :too_short && e[:count] == 8 }).to be true
    end

    it "password が129文字以上では登録できない（Devise既定は最大128）" do
      long = "a1" * 65  # 130文字
      user.password = long
      user.password_confirmation = long
      expect(user).to be_invalid
      expect(user.errors.details[:password].any? { |e| e[:error] == :too_long && e[:count] == 128 }).to be true
    end

    it "password と password_confirmation が不一致では登録できない" do
      user.password = "password123"
      user.password_confirmation = "password124"
      expect(user).to be_invalid
      expect(user.errors[:password_confirmation]).to be_present
    end
  end
end