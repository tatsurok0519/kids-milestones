# db/seeds.rb
require "yaml"
require "active_support/core_ext/hash/indifferent_access"

path = Rails.root.join("db/seeds/milestones.yml")
abort "[seeds] milestones.yml not found: #{path}" unless File.exist?(path)

rows = YAML.load_file(path)
abort "[seeds] milestones.yml must be an Array" unless rows.is_a?(Array)

puts "[seeds] loading milestones from #{path}"
created = 0
updated = 0
skipped = 0
failed  = 0

# ※ 全消ししたい時は CLEAR=1 を付けて実行
if ENV["CLEAR"] == "1"
  Milestone.delete_all
  puts "[seeds] cleared milestones table"
end

ActiveRecord::Base.transaction do
  rows.each_with_index do |raw, idx|
    row = raw.with_indifferent_access

    title       = row[:title].to_s.strip
    category    = row[:category].to_s.strip.presence
    difficulty  = row[:difficulty]
    min_months  = row[:min_months]
    max_months  = row[:max_months]
    # ヒントは description を優先。旧データの hint_text があれば暫定で description に入れる
    description = (row[:description].presence || row[:hint_text].presence)

    if title.blank?
      puts "[SKIP ##{idx}] title is blank"
      skipped += 1
      next
    end

    # 型/値の調整
    difficulty = difficulty.to_i if difficulty.present?
    difficulty = 2 unless (1..3).include?(difficulty) # 既定=2

    if min_months.present? && max_months.present? && min_months.to_i > max_months.to_i
      # min/max が逆になっていたら入れ替える
      min_months, max_months = max_months, min_months
    end

    # 自然キー（title + min/max）で upsert。月齢未指定なら title のみ
    finder = if min_months.present? || max_months.present?
      { title: title, min_months: min_months, max_months: max_months }
    else
      { title: title }
    end

    begin
      m = Milestone.find_or_initialize_by(finder)
      before_persisted = m.persisted?

      m.assign_attributes(
        title:       title,
        category:    category,
        difficulty:  difficulty,
        min_months:  min_months,
        max_months:  max_months,
        description: description # ← ここがヒント表示に使われます（モデル側で description 優先）
      )

      m.save!
      before_persisted ? updated += 1 : created += 1
    rescue => e
      failed += 1
      puts "[ERROR ##{idx}] #{title.inspect} : #{e.class} #{e.message}"
    end
  end
end

total = Milestone.count
puts "[seeds] milestones upserted -> created=#{created}, updated=#{updated}, skipped=#{skipped}, failed=#{failed}, total=#{total}"