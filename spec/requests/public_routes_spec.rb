require "rails_helper"

RSpec.describe "Public routes", type: :request do
  it "未ログインでも /tasks /chat /report は 200" do
    get "/tasks";  expect(response).to have_http_status(:ok)
    get "/chat";   expect(response).to have_http_status(:ok)
    get "/report"; expect(response).to have_http_status(:ok)
  end

  it "未ログインで /dashboard は サインインへリダイレクト" do
    get "/dashboard"
    expect(response).to have_http_status(:found).or have_http_status(:see_other)
    expect(response.location).to match(/sign_in/)
  end
end