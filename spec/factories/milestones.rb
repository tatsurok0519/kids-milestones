FactoryBot.define do
  factory :milestone do
    title { "はじめてのあんよ" }
    category { "motor" }
    difficulty { 2 }
    min_months { 10 }
    max_months { 14 }
  end
end