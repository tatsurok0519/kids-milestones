class Milestone < ApplicationRecord
  # months が nil のときは全年齢対象
  scope :for_age, ->(months) {
    where("(min_months IS NULL OR min_months <= ?) AND (max_months IS NULL OR max_months >= ?)", months, months)
  }
  validates :difficulty, inclusion: { in: 1..3 }
end