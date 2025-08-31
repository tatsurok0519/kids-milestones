module TasksHelper
  # Milestoneのヒントを取得する。
  # 1) ARのhint_textがあればそれを返す
  # 2) 無ければ db/seeds/milestones.yml を1回だけ読んで title マッチで拾う
  # 3) どれも無ければ空文字
  def milestone_hint_text(ms)
    # まずDBの値
    if ms.respond_to?(:hint_text) && ms.hint_text.present?
      return ms.hint_text
    end

    # YAMLをメモ化して読む
    @__ms_yaml_index ||= begin
      path = Rails.root.join("db", "seeds", "milestones.yml")
      if File.exist?(path)
        rows = YAML.safe_load(File.read(path),
                              permitted_classes: [Date, Time, Symbol],
                              aliases: true) || []
        rows.index_by { |h| h["title"] }
      else
        {}
      end
    rescue => e
      Rails.logger.warn("[tasks helper] YAML load failed: #{e.class}: #{e.message}")
      {}
    end

    row = @__ms_yaml_index[ms.try(:title)]
    (row && (row["hint_text"].presence || row["hint"].presence)) || ""
  end
end