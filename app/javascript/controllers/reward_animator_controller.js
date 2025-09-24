import { Controller } from "@hotwired/stimulus";

// <body data-controller="reward-animator"> の想定
export default class extends Controller {
  connect() {
    document.addEventListener("turbo:frame-load", (e) => {
      // 置換された <turbo-frame> 内をスキャン
      this.processMarkers(e.target);
    });
  }

  processMarkers(root) {
    const markers = root.querySelectorAll("[data-reward-unlocked]");
    if (!markers.length) return;

    this.ensureToastHost();

    markers.forEach((el) => {
      const toastHTML = el.dataset.toastHtml || "";
      // 1) 右上トーストを追加
      this.toasts.insertAdjacentHTML("beforeend", toastHTML);

      // 2) 演出（必要なら既存の関数を呼ぶ）
      this.fireAnimation(el.dataset.rewardUnlocked || "");

      // 3) 2度発火しないよう削除
      el.remove();
    });
  }

  fireAnimation(idsCsv) {
    // ここで既存の演出（紙吹雪など）を呼んでもOK
    // ひとまず簡易ハイライト
    document.body.classList.add("reward-pulse");
    setTimeout(() => document.body.classList.remove("reward-pulse"), 900);
    // console.debug("reward unlocked:", idsCsv);
  }

  ensureToastHost() {
    if (!this.toasts) {
      const host = document.createElement("div");
      host.id = "toasts";
      host.style.position = "fixed";
      host.style.top = "14px";
      host.style.right = "14px";
      host.style.zIndex = "9999";
      host.style.display = "flex";
      host.style.flexDirection = "column";
      host.style.gap = "8px";
      document.body.appendChild(host);
    }
  }

  get toasts() {
    return document.getElementById("toasts");
  }
}