require "rails_helper"

RSpec.describe "ドキュメント風出力デモ: 公開ページ", type: :request do
  describe "未ログインでも閲覧できるエンドポイント" do
    it "/tasks は 200 を返す" do
      get "/tasks"
      expect(response).to have_http_status(:ok)
    end

    it "/chat は 200 を返す" do
      get "/chat"
      expect(response).to have_http_status(:ok)
    end

    it "/report は 200 を返す" do
      get "/report"
      expect(response).to have_http_status(:ok)
    end
  end
end