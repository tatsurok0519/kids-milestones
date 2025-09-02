class ErrorsController < ActionController::Base
  layout "application"
  # 例外時はCSRFトークンが無いこともあるため、null_sessionで安全に処理
  protect_from_forgery with: :null_session

  TITLES = {
    404 => "ページが見つかりません",
    403 => "アクセスできません",
    422 => "処理できませんでした",
    500 => "エラーが発生しました"
  }.freeze

  MESSAGES = {
    404 => "URLが間違っているか、削除された可能性があります。",
    403 => "このページを見る権限がありません。",
    422 => "もう一度お試しください。",
    500 => "時間をおいて再度お試しください。"
  }.freeze

  def show
    exception = request.env["action_dispatch.exception"]

    # 例外からHTTPステータスを復元。なければパラメータ(code)→最後は500へフォールバック
    status =
      if exception
        ActionDispatch::ExceptionWrapper.status_code_for_exception(exception.class.name)
      else
        (params[:code].presence || 500).to_i
      end

    # 想定外のコードは500へ正規化
    status = 500 unless [403, 404, 422, 500].include?(status)

    # ビューで参照するために@code/@title/@messageを必ずセット
    @code    = status
    @title   = TITLES[@code]
    @message = MESSAGES[@code]

    # 切り分け用ログ（request_id付き）
    Rails.logger.warn(
      "[ErrorsController] status=#{@code} method=#{request.request_method} path=#{request.fullpath} "\
      "request_id=#{request.request_id} exception=#{exception&.class}: #{exception&.message}"
    )

    # turbo_stream 等のフォーマットにはHTMLを返さずヘッダだけ返却（誤配信防止）
    respond_to do |format|
      format.html { render :show, status: @code }
      format.any  { head @code }
    end
  end
end