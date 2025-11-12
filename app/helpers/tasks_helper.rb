module TasksHelper
  include ActionView::RecordIdentifier
  def task_card_frame_id(milestone)
    "task_card_#{milestone.id}"
  end

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

    # --- ここから追記（51〜100） ---
    "片足立ち（2–3秒）"                 => "task51.png",
    "片足立ち（2-3秒）"                  => "task51.png",
    "ボールを投げて受ける（近距離）"     => "task52.png",
    "はさみで直線を切れる"               => "task53.png",
    "丸・十字を描く"                     => "task54.png",
    "3–4語で説明する（誰が何を）"        => "task55.png",
    "3-4語で説明する（誰が何を）"         => "task55.png",
    "トイレのサインを伝える"             => "task56.png",
    "役割を決めて遊ぶ（店員さん）"       => "task57.png",
    "片付けのルールを守る（種類別）"     => "task58.png",
    "三輪車をこぐ"                       => "task59.png",
    "1〜5を数える"                       => "task60.png",
    "1-5を数える"                        => "task60.png",
    "小さなピースをつまむ"               => "task61.png",
    "まっすぐの線をなぞる"               => "task62.png",
    "あいさつが言える"                   => "task63.png",
    "短いお話を最後まで聞く"             => "task64.png",
    "ねんどで形を作れる"                 => "task65.png",
    "小さな水差しで水を注ぐ"             => "task66.png",
    "ひも通し準備（太いひも）"           => "task67.png",
    "ケンケン（片足で連続）"             => "task68.png",
    "はさみで曲線を切る"                 => "task69.png",
    "ひも通し・ビーズ通し"               => "task70.png",
    "10–20ピースのパズル"               => "task71.png",
    "10-20ピースのパズル"                => "task71.png",
    "自分の名前を書くまね"               => "task72.png",
    "気持ちを言葉で伝える"               => "task73.png",
    "簡単なお手伝い（テーブル拭き）"     => "task74.png",
    "ルールのある遊び（神経衰弱）"       => "task75.png",
    "けんけんで5歩進める"               => "task76.png",
    "時計やタイマーで待つ"               => "task77.png",
    "ひらがなをいくつか読む"             => "task78.png",
    "おはしの準備（練習箸）"             => "task79.png",
    "図形をなぞって描く"                 => "task80.png",
    "砂山でトンネルを作れる"             => "task81.png",
    "友だちと役割分担して遊ぶ"           => "task82.png",
    "簡単な迷路をなぞる"                 => "task83.png",
    "なわとび（1–3回連続）"              => "task84.png",
    "なわとび（1-3回連続）"               => "task84.png",
    "自転車（補助輪あり）"               => "task85.png",
    "ひも結びの手順を知る（蝶結び前段）" => "task86.png",
    "ひらがなを数文字読む/書く"          => "task87.png",
    "時間の見通しを立てる（あと5分）"     => "task88.png",
    "お金のやりとりごっこ"               => "task89.png",
    "簡単な料理を手伝う（ちぎりサラダ）" => "task90.png",
    "集団でのルールを理解（整列/順番）"   => "task91.png",
    "スキップができる"                   => "task92.png",
    "前まわりができる"                   => "task93.png",
    "側転ができる"                       => "task94.png",
    "逆上がりができる"                   => "task95.png",
    "縄跳びで10回跳べる"                 => "task96.png",
    "レゴ等を見本通りに組む"             => "task97.png",
    "1〜20を数え簡単な加算"              => "task98.png",
    "1-20を数え簡単な加算"               => "task98.png",
    "植物の世話を続ける"                 => "task99.png",
    "ボードゲームのルールを守る"         => "task100.png",
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