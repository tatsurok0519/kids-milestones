こどもすくすくカード
アプリケーション概要

こどもすくすくカード は、家庭での成長記録を “花丸” として楽しく残し、
到達ごとに メダル/トロフィー が解放されるごほうび演出で親子のモチベーションを高めるアプリです。
ダッシュボードでお子さまごとの状況を把握し、ふりかえりレポート を印刷して日記や連絡帳に貼れます。

できること

年齢帯・カテゴリ・難易度で「できるかな」項目を閲覧

各項目を がんばり中 / できた！ でワンタップ更新（Turbo Streams）

20・30…到達時に メダル/トロフィー を自動解放
┗ 右上トースト＆ダッシュボードのアイコンが光る演出（未視聴のまま次回起動でも再生）

子どもの写真・年齢・花丸通算を一覧/詳細で確認

ふりかえりレポート（印刷用スタイル対応）
┗ ごほうび一覧 / 年齢帯別「できた！」をまとめ、A4でPDF保存OK

レスポンシブ最適化（主要カード・モーダル・ナビ）
┗ タップ領域44px・視認性の高い配色・アクセシビリティ配慮

相談ページ（SSEベースの簡易チャット UI／今後拡張予定）

利用規約・プライバシーポリシー・「比べない育ち」ガイダンスの静的ページ

URL

本番環境（Render）: https://kids-milestones.onrender.com

※ Basic認証を有効にしている場合は、起動画面のID/Passを入力してください（環境変数 BASIC_AUTH_USER / BASIC_AUTH_PASSWORD）。

テスト用アカウント

未ログインでも 「できるかな」おためしモード で基本操作を試せます（ブラウザにのみ保存）。

保存やレポート印刷、相談の継続利用にはアカウント作成が必要です。

右上 マイページ → 新規登録

子どもを登録してダッシュボードへ

もし運営側でデモアカウントを配布している場合は下記に記載してください：

（例）Email: demo@example.com / Password: password

（例）Basic認証: user / pass
※ 実運用の値に置き換えてください。

利用方法

トップの ダッシュボード からお子さまを選択/追加

できるかな で年齢帯・カテゴリ・難易度を切り替え

各カード右下のボタンで がんばり中 / できた！ を切替

花丸が一定数に到達すると メダル/トロフィー が解放（トースト表示＋アイコン演出）

レポート（印刷） ボタンから A4 でPDF保存（@media print 対応）

相談ページに育児の悩みを書き込んでメモ（簡易チャットUI）

アプリケーションを作成した背景

「日々の成長を前向きに残したい」「できた/できないの比較ではなく、その子のペース を大切にしたい」という保護者の声から着想しました。
SNSのような公開性や“点数化”ではなく、家庭の記録 にフォーカス。
すぐに貼って残せる 印刷レポート と、小さな成功を祝う ごほうび演出 で継続を後押しします。

実装した機能（画像/GIF は Gyazo 推奨）

※ 下記は README 用の説明テンプレートです。実際のスクショ/動画URLに置き換えてください。

ダッシュボード（子ども一覧/花丸/ごほうび行）

例: https://gyazo.com/xxxxxxxx

できるかな（がんばり中/できた！切替）

例: https://gyazo.com/xxxxxxxx

ごほうび解放トースト＆アイコン演出（未視聴キュー＆セッション保持）

例: https://gyazo.com/xxxxxxxx

相談ページ（簡易チャットUI）

例: https://gyazo.com/xxxxxxxx

ふりかえりレポート（@media print でA4最適化）

例: https://gyazo.com/xxxxxxxx

エラーページ（403/404/422/500）ブランドトーンで案内

例: https://gyazo.com/xxxxxxxx

モバイル最適化（主要カード・ナビ・モーダル）

例: https://gyazo.com/xxxxxxxx

実装予定の機能

相談チャットの本格化（AI支援・カテゴリ分け・返信テンプレート）

花丸の週次/月次サマリー通知

子どもプロフィールの拡充（身長/体重など任意）

レポートの期間フィルタ/比較、画像レイアウトテンプレートの追加

アカウント招待（両親/祖父母など複数閲覧）

データベース設計（ER 図）
erDiagram
  USERS ||--o{ CHILDREN : has_many
  CHILDREN ||--o{ ACHIEVEMENTS : has_many
  CHILDREN ||--o{ REWARD_UNLOCKS : has_many
  REWARDS ||--o{ REWARD_UNLOCKS : has_many
  MILESTONES ||--o{ ACHIEVEMENTS : has_many

  USERS {
    bigint id PK
    string email
    string encrypted_password
    string name
    datetime created_at
  }

  CHILDREN {
    bigint id PK
    bigint user_id FK
    string name
    date birthday
    datetime created_at
    active_storage photo
  }

  MILESTONES {
    bigint id PK
    string title
    string category
    integer difficulty
    integer min_months
    integer max_months
  }

  ACHIEVEMENTS {
    bigint id PK
    bigint child_id FK
    bigint milestone_id FK
    boolean working
    boolean achieved
    datetime achieved_at
  }

  REWARDS {
    bigint id PK
    string kind        // medal or trophy
    string tier        // bronze/silver/gold
    integer threshold  // 20/30/...
    string icon_path
  }

  REWARD_UNLOCKS {
    bigint id PK
    bigint child_id FK
    bigint reward_id FK
    datetime unlocked_at
  }

画面遷移図（概略）
flowchart LR
  A[ランディング] --> B[ダッシュボード]
  B --> C[できるかな一覧]
  C -->|達成トグル| C
  B --> D[相談ページ]
  B --> E[レポート（印刷）]
  B --> F[マイページ/設定]
  F --> G[子ども登録・編集]
  B --> H[比べない育ち]
  B --> I[利用規約/プライバシー]

開発環境

Ruby 3.2 / Rails 7.1

DB: PostgreSQL（本番）/ SQLite（開発・テスト）

認証: Devise / 認可: Pundit

View: Turbo / Turbo Streams / Importmap / ERB

CSS: Tailwind CSS v4（@tailwindcss/cli）

画像: Active Storage（MiniMagick variants）
※ 本番のファイルストレージは任意（S3/Cloudinary等）

デプロイ: Render

テスト: Rails system test（rack_test ドライバ）, Minitest

ローカルでの動作方法
# 1) 取得
git clone <このリポジトリのURL>
cd kids-milestones

# 2) Ruby / Node / DB の準備（必要に応じて）
# rbenv で Ruby 3.2、Node 18+、PostgreSQL or SQLite

# 3) 依存インストール
bundle install
npm install  # または corepack enable / pnpm でも可

# 4) DB セットアップ
bin/rails db:setup   # schema + seeds

# 5) Tailwind ビルド（開発中は別ターミナルで --watch でもOK）
npm run build:css

# 6) 起動
bin/rails s
# http://localhost:3000

環境変数（本番）

BASIC_AUTH_USER, BASIC_AUTH_PASSWORD … Basic 認証（任意）

RAILS_MASTER_KEY … Rails credentials

（ストレージを外部にする場合）S3 / Cloudinary のキー

テスト実行
# rack_test ドライバでシステムテスト
SYSTEM_TEST_DRIVER=rack_test bin/rails test:system
# まとめて
bin/rails test

工夫したポイント

未視聴リワードの管理：セッションにキューし、次回ダッシュボードでも必ず演出を再生

アクセシビリティ：prefers-reduced-motion で演出無効、フォーカス可視化、タップ領域44px

パフォーマンス：

LCP対象画像に fetchpriority=high、その他は loading="lazy" decoding="async"

ActiveStorageの サムネイルバリアント を徹底

N+1 を includes / with_attached_photo で削減

@media print：ヘッダー/ナビ制御、A4 余白、影/背景除去で PDF 印刷に最適化

ブランドトーン：やわらかい配色（サニー×はちみつ色）、ごほうび演出で前向きさを演出

改善点

相談機能の双方向化（返信/通知）とガイドの充実

レポートのレイアウトテンプレート（写真複数・コメント欄）

モバイルの一部ページでの初回LCPの追加最適化（プリロード/寸法の更なる明示）

管理画面（マスタ・しきい値編集、メッセージ配信）

国際化（i18n） & ユニットテストの拡充

制作時間

企画・UIデザイン・実装・調整を含めて （開発者の実績値を記載してください）
例）合計 XX 時間

付録：セキュリティ・運用メモ

CSRF: Rails 既定の保護有効、API以外は protect_from_forgery（既定）

強制ログイン: 各Controllerで before_action :authenticate_user!（公開ページは skip_before_action）

入力バリデーション: モデルでpresence/format、Punditで権限制御

個人情報の公開範囲: 画像URL/氏名の公開をコントローラ/ポリシーで限定

エラーページ: 403/404/422/500 をブランドトーンで案内、戻る/トップ導線つき