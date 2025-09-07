module TasksHelper
  # ---------- ヒント（既存） ----------
  def milestone_hint_text(ms)
    if ms.respond_to?(:hint_text) && ms.hint_text.present?
      return ms.hint_text
    end

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

  # ---------- 小イラスト表示用 ----------
  # 文字列を比較しやすく正規化する
  # - 前後の空白を削る（strip）
  # - 連続空白を1個に潰す（全角スペースも対象）
  # - 文末の（…） or (…) などの括弧内注釈を削除
  def normalize_task_key(str)
    s = str.to_s

    # 前後のあらゆる空白（全角スペース含む）を除去
    s = s.gsub(/\A[[:space:]]+|[[:space:]]+\z/, "")

    # 連続空白を半角スペース1つに
    s = s.gsub(/[[:space:]]+/, " ")

    # タイトル末尾の注釈（全角/半角カッコに対応）を除去
    # 例: "目で物を追う（トラッキング）" → "目で物を追う"
    s = s.sub(/[（(].*[)）]\z/, "")

    s
  end
  module_function :normalize_task_key

  # ここに「カード識別子 => 画像ファイル名」を追加
  RAW_TASK_SMALL_THUMBS = {
    "目で物を追う（トラッキング）"            => "task1.png",
    "うつ伏せで首を上げる（タミータイム）"    => "task2.png",
    "ガラガラを握る"                         => "task3.png",
    "寝返り（仰向け→うつ伏せ）"              => "task4.png",
    "おすわり（補助あり）"                   => "task5.png",
    "両手で持ち替える"                       => "task6.png",
    "名前を呼ばれて振り向く"                 => "task7.png",
    "バブリング（ばばば等）"                 => "task8.png",
    "手を口に運ぶ"                           => "task9.png",
    "足をつかむ"                             => "task10.png",
  }.freeze

  # 対応表のキーも正規化しておく
  TASK_SMALL_THUMBS = RAW_TASK_SMALL_THUMBS.transform_keys { |k| normalize_task_key(k) }.freeze

  # milestone から候補キーを作って順に検索
  def task_small_thumb_path(task)
    candidates = []

    # slug/code があれば最優先
    candidates << task.slug if task.respond_to?(:slug) && task.slug.present?
    candidates << task.code if task.respond_to?(:code) && task.code.present?

    # タイトル系
    title = task.title.to_s
    candidates << title
    candidates << title.split(/[（(]/).first # かっこの手前
    candidates << title.gsub(/[（(].*?[)）]/, "") # かっこ内を全部除去

    candidates.uniq!

    candidates.each do |key|
      next if key.blank?
      hit = TASK_SMALL_THUMBS[normalize_task_key(key)]
      return hit if hit.present?
    end

    # 見つからなければ nil
    nil
  end
end