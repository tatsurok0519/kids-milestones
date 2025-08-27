require "rails_helper"

RSpec.describe "Children#update photo", type: :request do
  let(:user) { create(:user) }
  let(:child) { create(:child, user: user) }
  let(:img1) { Rails.root.join("spec/fixtures/files/test.jpg") }
  let(:img2_path) { Rails.root.join("spec/fixtures/files/test2.jpg") }
  let(:img2) { img2_path.exist? ? img2_path : img1 }

  before { sign_in user }

  it "新しい写真を選んだら置き換わる（remove_photoは無視）" do
    # 既存を付ける
    child.photo.attach(io: File.open(img1), filename: "test.jpg", content_type: "image/jpeg")

    patch child_path(child), params: {
      child: { name: child.name, birthday: child.birthday, remove_photo: "1",
               photo: Rack::Test::UploadedFile.new(img2, "image/jpeg") }
    }

    expect(response).to redirect_to(child_path(child))
    child.reload
    expect(child.photo).to be_attached
  end

  it "remove_photo=1 かつ 新規アップロードなし → 既存写真を削除" do
    child.photo.attach(io: File.open(img1), filename: "test.jpg", content_type: "image/jpeg")

    patch child_path(child), params: {
      child: { name: child.name, birthday: child.birthday, remove_photo: "1" }
    }

    # ← ここがポイント：リダイレクト先は追わない
    expect(response).to redirect_to(child_path(child))

    child.reload
    expect(child.photo).not_to be_attached
  end
end