import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = []

  connect() {
    // 初回 & フレーム更新後の両方でスキャン
    this.scan();
    document.addEventListener("turbo:frame-load", () => this.scan());
    document.addEventListener("turbo:load",       () => this.scan());
  }

  scan() {
    const markers = document.querySelectorAll('[data-reward-unlocked]');
    if (!markers.length) return;

    markers.forEach((el) => {
      try {
        const ids  = (el.dataset.rewardUnlocked || "").trim();
        // ① template 内の HTML を優先
        const tmpl = el.querySelector('template[data-reward-toast]');
        let html   = tmpl ? tmpl.innerHTML : null;

        // ② 互換: data-toast-html（旧実装）
        if (!html && el.dataset.toastHtml) {
          html = el.dataset.toastHtml; // 旧属性（あればそのまま使う）
        }

        // ③ 最後の砦: フォールバック文
        if (!html) {
          html = `<div class="toast">ごほうび解放！ <small>ID: ${ids}</small></div>`;
        }

        // トーストレイヤへ追加
        const layer = document.getElementById("toasts");
        if (layer) layer.insertAdjacentHTML("beforeend", html);

        // 1回使ったら削除（再発火防止）
        el.remove();
      } catch (e) {
        console.error("[reward-animator] failed:", e);
      }
    });
  }
}