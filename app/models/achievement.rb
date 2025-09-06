class Achievement < ApplicationRecord
  belongs_to :child
  belongs_to :milestone

  # 以前入れた :saved_change_to_state? は間違い
  # 「達成フラグが変わったとき」に同期すればOK
  after_commit :sync_rewards_if_needed

  private

  def sync_rewards_if_needed
    # achieved が変わったときだけで十分（working で花丸数は変わらない）
    return unless saved_change_to_achieved?

    # 既存コントローラが RewardUnlocker.call(child) を呼んでいても
    # idempotent（find_or_create_by）なので二重呼び出しでも安全です。
    RewardUnlocker.call(child)
  end
end