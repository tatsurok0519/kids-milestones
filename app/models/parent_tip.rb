require "yaml"

class ParentTip
  PATH = Rails.root.join("config/parent_tips.yml")

  class << self
    def for(child: nil, date: Date.current)
      list = tips_for(child)&.uniq || []
      return default_tip(child) if list.empty?

      # 「毎日ひとつ、ユーザー（子）ごとに安定」な選び方
      seed = (date.yday + (child&.id || 0)) # 年内で回る・子どもごとにズレる
      list[seed % list.size]
    end

    private

    def tips_for(child)
      data = load_data
      bands = []
      bands << "band_#{child.age_band_index}" if child
      # 年齢帯向け + 全年齢向けをマージ
      (data[bands.first] || []) + (data["all"] || [])
    end

    def load_data
      @data ||= begin
        if File.exist?(PATH)
          YAML.load_file(PATH).to_h
        else
          {}
        end
      rescue => _
        {}
      end
    end

    def default_tip(child)
      if child
        "#{child.name}さんのペースでOK。短時間でも“できた感”を積み重ねましょう。"
      else
        "今日は深呼吸から。短い時間でも、お子さんの“できた！”を見つけて言葉に。"
      end
    end
  end
end