class ErrorsController < ActionController::Base
  layout "application"
  protect_from_forgery with: :null_session

  def show
    status = params[:code].to_s.presence_in(%w[404 403 422 500]) || "500"

    @title, @message =
      case status
      when "404" then ["ページが見つかりません", "URLが間違っているか、削除された可能性があります。"]
      when "403" then ["アクセスできません", "このページを見る権限がありません。"]
      when "422" then ["処理できませんでした", "もう一度お試しください。"]
      else            ["エラーが発生しました", "時間をおいて再度お試しください。"]
      end

    render status: status
  end
end