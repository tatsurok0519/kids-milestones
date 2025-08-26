# app/services/recommendation_picker.rb
class RecommendationPicker
  # 未達から「きょうのおすすめ」を3件（カテゴリ多様性＋★低め優先＋日替わり安定）
  def self.for_child(child, k: 3)
    return [] if child.blank?

    # すでに達成したものは除外
    achieved_ids = child.achievements.where(achieved: true).pluck(:milestone_id)

    # ★（難易度）昇順でベース候補
    candidates = Milestone.where.not(id: achieved_ids).order(:difficulty).to_a
    return candidates.first(k) if candidates.size <= k

    # 「同じ日なら同じ並び」を作るためのシード（子どもごとに少し変える）
    seed = Date.current.strftime("%Y%m%d").to_i + child.id
    rng  = Random.new(seed)

    # カテゴリごとに分けて“なるべくバラける”ように取っていく
    by_cat    = candidates.group_by(&:category)
    cat_order = by_cat.keys.sort_by { rng.rand }  # 日替わり・安定シャッフル

    picks = []
    while picks.size < k && by_cat.values.any?(&:any?)
      cat_order.each do |cat|
        break if picks.size >= k
        list = by_cat[cat]
        next if list.empty?
        idx = (rng.rand * list.size).floor
        picks << list.delete_at(idx)
      end
    end

    # もしカテゴリの偏りで3件満たなければ残りを埋める
    if picks.size < k
      rest = (candidates - picks)
      picks.concat(rest.first(k - picks.size))
    end

    picks
  end
end