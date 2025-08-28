Milestone.destroy_all

require "yaml"
path = Rails.root.join("db/seeds/milestones.yml")

if File.exist?(path)
  puts "[seeds] loading milestones from #{path}"
  data = YAML.load_file(path) || []
  data.each do |row|
    next if row.blank? || row["title"].blank?
    m = Milestone.find_or_initialize_by(title: row["title"])
    m.category    = row["category"]
    m.difficulty  = row["difficulty"]
    m.min_months  = row["min_months"]
    m.max_months  = row["max_months"]
    m.hint_text   = row["hint_text"]
    m.save!
  end
  puts "[seeds] milestones upserted: #{data.size}"
else
  puts "[seeds] milestones.yml not found, skipping"
end