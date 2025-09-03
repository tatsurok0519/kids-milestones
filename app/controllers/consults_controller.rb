require "net/http"
require "uri"
require "json"

class ConsultsController < ApplicationController
  include ActionController::Live
  skip_before_action :verify_authenticity_token, only: :stream

  before_action :ensure_openai_key!, only: [:show, :stream]
  before_action :set_breadcrumbs,     only: :show

  # GET /consult
  def show
    # ビュー表示のみ
  end

  # GET /consult/stream?q=...
  # Server-Sent Events で OpenAI のストリームをそのまま中継
  def stream
    # --- SSE ヘッダ（プロキシのバッファ無効/圧縮無効/キャッシュ無効） ---
    response.headers["Content-Type"]        = "text/event-stream; charset=utf-8"
    response.headers["Cache-Control"]       = "no-cache, no-transform"
    response.headers["Connection"]          = "keep-alive"
    response.headers["X-Accel-Buffering"]   = "no"
    response.headers["Last-Modified"]       = Time.now.httpdate

    sse = ActionController::Live::SSE.new(response.stream, retry: 3000)

    # 接続通知（UI側の疎通確認用）
    sse.write({ message: "connected" }.to_json, event: "system")

    q = params[:q].to_s.strip
    if q.blank?
      sse.write("相談内容を入力してください。", event: "token")
      sse.write("", event: "done")
      return
    end

    uri = URI.parse("https://api.openai.com/v1/chat/completions")

    # Net::HTTP.start を使って接続を管理（keep-alive/タイムアウト強化）
    Net::HTTP.start(uri.host, uri.port, use_ssl: true, read_timeout: 300, open_timeout: 30) do |http|
      req = Net::HTTP::Post.new(uri.request_uri)
      req["Authorization"]    = "Bearer #{openai_api_key}"
      req["Content-Type"]     = "application/json"
      req["Accept"]           = "text/event-stream"
      req["Accept-Encoding"]  = "identity" # 圧縮無効（行分割が壊れないように）

      req.body = {
        model:   "gpt-4o-mini",
        stream:  true,
        messages: [
          {
            role: "system",
            content: "あなたは子育ての相談相手です。相手をねぎらい、根拠に基づき、断定を避け、やさしい日本語で答えてください。医療や緊急の判断が必要な場合は受診・相談先を案内します。"
          },
          { role: "user", content: q }
        ],
        max_tokens: 800
      }.to_json

      http.request(req) do |res|
        if res.code.to_i >= 400
          Rails.logger.error("[consult stream] HTTP #{res.code} #{res.message}")
          sse.write("（接続に失敗しました: HTTP #{res.code}）", event: "token")
          sse.write("", event: "done")
          next
        end

        # OpenAI からの SSE を行単位でパース
        last_beat = Time.now

        res.read_body do |chunk|
          # ハートビート（15秒無通信なら疎通確認）
          if Time.now - last_beat > 15
            sse.write({ at: Time.current.iso8601 }.to_json, event: "heartbeat")
            last_beat = Time.now
          end

          chunk.each_line do |line|
            next unless line.start_with?("data:")
            data = line.sub(/\Adata:\s?/, "").strip
            break if data == "[DONE]"

            begin
              json  = JSON.parse(data)
              delta = json.dig("choices", 0, "delta", "content")
              # 'role' が来る最初のチャンクは無視してOK
              sse.write(delta.to_s, event: "token") if delta
            rescue JSON::ParserError
              # まれに data: の後に空行/制御文字が来る場合がある→無視
              next
            end
          end
        end
      end
    end
  rescue IOError => e
    # クライアント切断など
    Rails.logger.info("[consult stream] client disconnected: #{e.class}")
  rescue => e
    Rails.logger.error("[consult stream] #{e.class}: #{e.message}")
    begin
      sse.write("\n[サーバでエラーが発生しました]", event: "token")
    rescue
      # noop
    end
  ensure
    begin
      sse.write("", event: "done")
    rescue
      # noop
    end
    # ストリームを必ず閉じる
    begin
      sse.close
      response.stream.close
    rescue
      # noop
    end
  end

  private

  def set_breadcrumbs
    if respond_to?(:add_crumb)
      add_crumb("ダッシュボード", dashboard_path) if user_signed_in?
      add_crumb("そうだん", consult_path)
    end
  end

  def openai_api_key
    ENV["OPENAI_API_KEY"] || Rails.application.credentials.dig(:openai, :api_key)
  end

  def ensure_openai_key!
    unless openai_api_key.present?
      render plain: "相談機能はセットアップ中です（OPENAI_API_KEY 未設定）。", status: :service_unavailable
    end
  end
end