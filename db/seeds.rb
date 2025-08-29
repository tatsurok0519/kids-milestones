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

# ▼ CLEAR=1 のときは FK を考慮して安全に全消し
if ENV["CLEAR"] == "1"
  puts "[seeds] CLEAR=1 -> deleting achievements then milestones"
  ActiveRecord::Base.connection.disable_referential_integrity do
    Achievement.delete_all
    Milestone.delete_all
  end
  puts "[seeds] cleared milestones & achievements"
end

ActiveRecord::Base.transaction do
  rows.each_with_index do |raw, idx|
    row = raw.with_indifferent_access

    title       = row[:title].to_s.strip
    category    = row[:category].to_s.strip.presence
    difficulty  = row[:difficulty]
    min_months  = row[:min_months]
    max_months  = row[:max_months]
    description = (row[:description].presence || row[:hint_text].presence)

    if title.blank?
      puts "[SKIP ##{idx}] title is blank"
      skipped += 1
      next
    end

    difficulty = difficulty.to_i if difficulty.present?
    difficulty = 2 unless (1..3).include?(difficulty)

    if min_months.present? && max_months.present? && min_months.to_i > max_months.to_i
      min_months, max_months = max_months, min_months
    end

    # 自然キー（title + min/max ありの場合は三つ組、無ければ title 単独）
    finder =
      if min_months.present? || max_months.present?
        { title: title, min_months: min_months, max_months: max_months }
      else
        { title: title }
      end

    begin
      m = Milestone.find_or_initialize_by(finder)
      before = m.persisted?
      m.assign_attributes(
        title:       title,
        category:    category,
        difficulty:  difficulty,
        min_months:  min_months,
        max_months:  max_months,
        description: description
      )
      m.save!
      before ? updated += 1 : created += 1
    rescue => e
      failed += 1
      puts "[ERROR ##{idx}] #{title.inspect} : #{e.class} #{e.message}"
    end
  end
end

total = Milestone.count
puts "[seeds] upserted -> created=#{created}, updated=#{updated}, skipped=#{skipped}, failed=#{failed}, total=#{total}"