FactoryBot.define do
  factory :child do
    association :user
    name { "はると" }
    birthday { Date.new(2021, 5, 15) }

    # 画像添付などが必要になったらここに trait を追加してください
    # trait :with_photo do
    #   after(:build) { |child| child.photo.attach(io: File.open(Rails.root.join("spec/fixtures/files/sample.jpg")), filename: "sample.jpg", content_type: "image/jpeg") }
    # end
  end
end