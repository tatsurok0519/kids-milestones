FactoryBot.define do
  factory :user do
    name  { "Taro" }
    email { Faker::Internet.unique.email }
    password { "password123" }
    password_confirmation { password }

    # 任意：子どもを同時作成したいときに使えるトレイト
    transient do
      children_count { 0 }
    end

    after(:create) do |user, evaluator|
      create_list(:child, evaluator.children_count, user: user) if evaluator.children_count.to_i > 0
    end
  end
end