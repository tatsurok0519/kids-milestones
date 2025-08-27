class Achievement < ApplicationRecord
  belongs_to :child
  belongs_to :milestone

  # 子ども × マイルストーン は一意
  validates :milestone_id, uniqueness: { scope: :child_id,
    message: "はこの子に対して既に達成済みです" }
end