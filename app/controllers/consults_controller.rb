require "net/http"
require "uri"
require "json"

class ConsultsController < ApplicationController
  include ActionController::Live

  before_action :ensure_openai_key!
  before_action :set_breadcrumbs, only: :show
  skip_forgery_protection only: :stream # GET だが環境によって弾かれる保険

  # GET /consult
  def show
    # ビュー表示だけ
  end

  # GET /consult/stream?q=...
  def stream
    # SSE ヘッダ
    response.headers["Content-Type"]      = "text/event-stream; charset=utf-8"
    response.headers["Cache-Control"]     = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"
    response.headers["Last-Modified"]     = Time.now.httpdate

    sse = ActionController::Live::SSE.new(response.stream)

    q = params[:q].to_s.strip
    if q.blank?
      sse.write("相談内容を入力してください。", event: "token")
      sse.write("", event: "done")
      return
    end

    begin
      uri  = URI.parse("https://api.openai.com/v1/chat/completions")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl      = true
      http.read_timeout = 300

      req = Net::HTTP::Post.new(uri.request_uri)
      req["Authorization"] = "Bearer #{openai_api_key}"
      req["Content-Type"]  = "application/json"
      req.body = {
        model: "gpt-4o-mini",
        stream: true,
        messages: [
          { role: "system", content: "あなたは子育ての相談相手です。相手をねぎらい、根拠に基づき、断定を避け、やさしい日本語で答えてください。医療や緊急の判断が必要な場合は受診・相談先を案内します。" },
          { role: "user",   content: q }
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

        # OpenAIの event-stream を1行ずつパース
        res.read_body do |chunk|
          chunk.each_line do |line|
            next unless line.start_with?("data:")
            data = line[5..].strip
            break if data == "[DONE]"
            begin
              json  = JSON.parse(data)
              delta = json.dig("choices", 0, "delta", "content")
              sse.write(delta.to_s, event: "token") if delta
            rescue JSON::ParserError
              # 途中のハートビートなどは捨てる
            end
          end
        end
      end

    rescue => e
      Rails.logger.error("[consult stream] #{e.class}: #{e.message}")
      sse.write("\n[サーバでエラーが発生しました]", event: "token")
    ensure
      # クライアント側の完了ハンドラ用に必ず done を送ってから閉じる
      sse.write("", event: "done") rescue nil
      sse.close rescue nil
      response.stream.close rescue nil
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