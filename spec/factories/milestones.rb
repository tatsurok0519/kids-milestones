FactoryBot.define do
  factory :milestone do
    sequence(:title) { |n| "はじめてのあんよ#{n}" } # 重複回避（ユニーク制約がなくても安全）
    category   { "motor" }
    difficulty { 2 }
    min_months { 10 }
    max_months { 14 }
    # モデルで必須なら有効化してください
    # description { "説明テキスト" }

    trait :easy do
      difficulty { 1 }
    end

    trait :normal do
      difficulty { 2 }
    end

    trait :hard do
      difficulty { 3 }
    end
  end
end