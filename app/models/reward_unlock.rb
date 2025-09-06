class RewardUnlock < ApplicationRecord
  belongs_to :child
  belongs_to :reward

  # ない場合は現在時刻で補完（NOT NULL対策 / 作成時・更新時どちらでも安全）
  before_validation :ensure_unlocked_at

  # --- Validations ---
  validates :child_id,    presence: true
  validates :reward_id,   presence: true
  validates :unlocked_at, presence: true
  validates :reward_id,   uniqueness: { scope: :child_id }  # 複合一意

  private

  def ensure_unlocked_at
    # 環境差異で列が無いケースも想定して防御
    return unless has_attribute?(:unlocked_at)
    self.unlocked_at ||= Time.current
  end
end