module TasksHelper
  # ===== ヒント文の取得（既存ロジック） =====
  def milestone_hint_text(ms)
    if ms.respond_to?(:hint_text) && ms.hint_text.present?
      return ms.hint_text
    end

    @__ms_yaml_index ||= begin
      path = Rails.root.join("db", "seeds", "milestones.yml")
      if File.exist?(path)
        rows = YAML.safe_load(
          File.read(path),
          permitted_classes: [Date, Time, Symbol],
          aliases: true
        ) || []
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

  # ====== 小イラスト対応表（タイトル => 画像パス） ======
  # 画像は app/assets/images/task1.png ... task50.png として配置
  TASK_SMALL_THUMBS = {
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

    # 11〜50
    "おもちゃを叩く・鳴らす"                 => "task11.png",
    "親の表情をまねる"                       => "task12.png",
    "いないいないばあに反応する"             => "task13.png",
    "自分の名前を理解する"                   => "task14.png",
    "小さな物に手を伸ばす"                   => "task15.png",
    "おすわり（手放しで数秒）"               => "task16.png",
    "ひとり歩き（数歩〜）"                   => "task17.png",
    "コップで飲む"                           => "task18.png",
    "スプーンで食べる"                       => "task19.png",
    "積み木を2–4個積む"                      => "task20.png",
    "積み木を2-4個積む"                      => "task20.png", # ハイフンゆれ対策
    "型はめパズル（丸・三角・四角）"          => "task21.png",
    "指差しで伝える（欲しい物）"             => "task22.png",
    "簡単な指示に従う（ちょうだい）"         => "task23.png",
    "なぐり書きスタート"                     => "task24.png",
    "ボールを転がして返す"                   => "task25.png",
    "絵本のページをめくる"                   => "task26.png",
    "服を脱ぐのを手伝う"                     => "task27.png",
    "靴や靴下を持ってくる"                   => "task28.png",
    "短い言葉をまねる"                       => "task29.png",
    "絵を指示で探す（犬どれ？）"             => "task30.png",
    "ブロックを入れて出す"                   => "task31.png",
    "お片付けを一緒にする"                   => "task32.png",
    "両手でコップを持つ"                     => "task33.png",
    "両足ジャンプ（その場）"                 => "task34.png",
    "階段を手すりで上り下り"                 => "task35.png",
    "なぐり書き（線・丸）"                   => "task36.png",
    "2語文で伝える（ママ来て）"              => "task37.png",
    "ごっこ遊び（ままごと）"                 => "task38.png",
    "手洗い（泡立て→すすぎ）"               => "task39.png",
    "3–6ピースのパズル"                      => "task40.png",
    "3-6ピースのパズル"                      => "task40.png", # ハイフンゆれ対策
    "服の着脱の一部（袖）"                   => "task41.png",
    "ボールを蹴る"                           => "task42.png",
    "大きなボールを受ける"                   => "task43.png",
    "色で分類する"                           => "task44.png",
    "順番を待つ"                             => "task45.png",
    "フォークを使う"                         => "task46.png",
    "ふた付き容器を開け閉め"                 => "task47.png",
    "歯みがき（大人と一緒に）"               => "task48.png",
    "登場人物を指差しで説明"                 => "task49.png",
    "自分の名前を言う"                       => "task50.png",
  }.freeze

  # ===== キー正規化：空白除去 + ハイフン類の統一など =====
  def normalize_task_key(str)
    s = str.to_s
    s = s.tr("　", " ")                 # 全角スペース→半角
    s = s.tr("‐-–−", "-")              # ハイフン/ダッシュ類を統一
    s = s.tr("~～", "〜")               # チルダ/全角波ダッシュを統一
    s.gsub(/[[:space:]]+/, "")          # すべての空白を除去
  end

  # task から対応画像パスを返す（なければ nil）
  def task_small_thumb_path(task)
    raw_key =
      if task.respond_to?(:slug) && task.slug.present?
        task.slug
      elsif task.respond_to?(:code) && task.code.present?
        task.code
      else
        task.title.to_s
      end

    @__thumbs_norm ||= TASK_SMALL_THUMBS.transform_keys { |k| normalize_task_key(k) }
    @__thumbs_norm[normalize_task_key(raw_key)]
  end
end