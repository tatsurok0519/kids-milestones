FactoryBot.define do
  factory :user do
    name  { "Taro" }
    email { Faker::Internet.unique.email }
    password { "password123" }
  end
end