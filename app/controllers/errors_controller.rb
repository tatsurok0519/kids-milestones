class ErrorsController < ApplicationController
  # ここは誰でも見られるように
  skip_before_action :authenticate_user!
  layout "application"

  def show
    @code = (params[:code] || status_code_from_request || 500).to_i

    case @code
    when 404
      @title   = "ページが見つかりません"
      @message = "URLが間違っているか、移動・削除された可能性があります。"
    when 403
      @title   = "アクセスできません"
      @message = "権限がないか、ログインが必要です。"
    else
      @title   = "エラーが発生しました"
      @message = "ご不便をおかけしています。しばらくしてから再度お試しください。"
    end

    respond_to do |f|
      f.html { render :show, status: @code }
      f.turbo_stream { head @code } # Turbo遷移中は画面を壊さない
      f.json { render json: { error: @title, code: @code }, status: @code }
    end
  end

  private

  # 例外オブジェクトがあればそこからコードを推定
  def status_code_from_request
    ex = request.env["action_dispatch.exception"]
    return nil unless ex

    ActionDispatch::ExceptionWrapper.status_code_for_exception(ex.class.name)
  rescue
    nil
  end
end