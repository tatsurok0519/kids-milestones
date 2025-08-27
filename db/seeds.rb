Milestone.destroy_all

items = [
  { title: "ねんどで形を作れる", category: "手先・創造", difficulty: 1 },
  { title: "砂山でトンネルを作れる", category: "外遊び・感覚", difficulty: 1 },
  { title: "はさみで直線を切れる", category: "手先・創造", difficulty: 1 },
  { title: "けんけんで5歩進める", category: "運動・バランス", difficulty: 2 },
  { title: "スキップができる", category: "運動・バランス", difficulty: 2 },
  { title: "前まわりができる", category: "運動・体操", difficulty: 2 },
  { title: "側転ができる", category: "運動・体操", difficulty: 3 },
  { title: "逆上がりができる", category: "運動・体操", difficulty: 3 },
  { title: "縄跳びで10回跳べる", category: "運動・バランス", difficulty: 3 },
]
items.each { |h| Milestone.create!(h) }
puts "Milestones: #{Milestone.count}"

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
    m.save!
  end
  puts "[seeds] milestones upserted: #{data.size}"
else
  puts "[seeds] milestones.yml not found, skipping"
end