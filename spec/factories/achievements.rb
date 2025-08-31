FactoryBot.define do
  factory :achievement do
    association :child
    association :milestone

    # デフォルトは未着手
    working     { false }
    achieved    { false }
    achieved_at { nil }

    # 状態別トレイト
    trait :working do
      working     { true }
      achieved    { false }
      achieved_at { nil }
    end

    trait :achieved do
      transient do
        achieved_at_time { Time.current }
      end

      working     { false }
      achieved    { true }
      achieved_at { achieved_at_time }
    end

    trait :cleared do
      working     { false }
      achieved    { false }
      achieved_at { nil }
    end

    # 使い分けしやすいエイリアス（任意）
    factory :achievement_working,  traits: [:working]
    factory :achievement_achieved, traits: [:achieved]
    factory :achievement_cleared,  traits: [:cleared]
  end
end