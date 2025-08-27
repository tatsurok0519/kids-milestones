FactoryBot.define do
  factory :child do
    association :user
    name { "はると" }
    birthday { Date.new(2021, 5, 15) }
  end
end