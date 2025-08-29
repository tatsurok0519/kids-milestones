# OPENAI_API_KEY を環境変数に入れてください（.env などは任意）
# 例: export OPENAI_API_KEY="sk-xxxx"
OpenAI_CLIENT = OpenAI::Client.new(
  api_key: ENV.fetch("OPENAI_API_KEY")
)

key = ENV["OPENAI_API_KEY"] || Rails.application.credentials.dig(:openai, :api_key)

if key.present?
  OPENAI_CLIENT = OpenAI::Client.new(api_key: key)
else
  Rails.logger.warn("[openai] OPENAI_API_KEY が未設定です。相談チャットは無効化されます。")
  OPENAI_CLIENT = nil
end