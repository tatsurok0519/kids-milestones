key = ENV["OPENAI_API_KEY"] || Rails.application.credentials.dig(:openai, :api_key)

if key.present?
  OpenAI_CLIENT = OpenAI::Client.new(api_key: key)
else
  Rails.logger.warn("[openai] OPENAI_API_KEY が未設定です。相談チャットは無効化されます。")
  OpenAI_CLIENT = nil
end