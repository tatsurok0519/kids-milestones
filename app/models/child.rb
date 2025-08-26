class Child < ApplicationRecord
  belongs_to :user
  has_many :achievements, dependent: :destroy
  has_many :milestones, through: :achievements
  has_one_attached :photo # ActiveStorage（次の手順で有効化）

  # 生後月齢を計算する
  def age_in_months
    return nil unless birthdate
    (Date.current.year - birthdate.year) * 12 + Date.current.month - birthdate.month - (Date.current.day < birthdate.day ? 1 : 0)
  end

  # 生後週数を計算する
  def age_in_weeks
    return nil unless birthdate
    (Date.current - birthdate).to_i / 7
  end
end