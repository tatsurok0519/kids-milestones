// app/javascript/controllers/application.js
import { Application } from "@hotwired/stimulus"

const application = Application.start()

// 本番向けに静かに
application.debug = false
// DevTools から Stimulus を参照できるように（任意）
window.Stimulus = application

// ここがポイント：コントローラ内例外で全体が落ちないようにログだけ出す
application.handleError = (error, message, detail) => {
  // 必要なら Sentry 等へ送信
  console.error("[Stimulus]", message, detail, error)
}

export { application }