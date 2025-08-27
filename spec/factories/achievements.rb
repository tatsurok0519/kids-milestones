FactoryBot.define do
  factory :achievement do
    association :child
    association :milestone
  end
end