class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_child

  def show
    authorize @child, :use?

    # 達成（花丸） ※N+1防止
    @achievements = @child.achievements
                          .where(achieved: true)
                          .includes(:milestone)
                          .order(achieved_at: :asc)

    @total_hanamaru = @achievements.size

    # ごほうび（解放済） ※N+1防止
    @reward_unlocks = @child.reward_unlocks.includes(:reward)
                           .order("rewards.kind ASC, rewards.threshold ASC")

    # 年齢帯ごと（Milestone に age_band_label が無い環境でも安全に算出）
    @by_band = @achievements.group_by { |a| band_label_for(a.milestone, @child) }
  end

  private

  def set_child
    @child = policy_scope(Child).with_attached_photo.find(params[:child_id])
  end

  # ---- helpers ----
  # Milestone から年齢帯ラベル ("0–1歳" など) を安全に作る
  def band_label_for(milestone, child)
    return "#{child.age_band_index}–#{child.age_band_index + 1}歳" if milestone.nil?

    # Demo 環境などで age_band_labels があればそれを優先利用（例: "0–1歳 1–2歳"）
    if milestone.respond_to?(:age_band_labels)
      lbl = milestone.age_band_labels.to_s.strip
      return lbl.presence || default_label(child)
    end

    # min_months / max_months から代表帯を決める（min があればそれ優先）
    mn = milestone.try(:min_months)
    mx = milestone.try(:max_months)

    idx =
      if mn
        (mn.to_i / 12).clamp(0, 5)
      elsif mx
        (([mx.to_i - 1, 0].max) / 12).clamp(0, 5)
      else
        child ? child.age_band_index : 0
      end

    "#{idx}–#{idx + 1}歳"
  end

  def default_label(child)
    idx = child ? child.age_band_index : 0
    "#{idx}–#{idx + 1}歳"
  end
end