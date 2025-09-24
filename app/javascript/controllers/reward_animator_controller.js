import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    document.addEventListener("turbo:frame-load", (e) => {
      this.processMarkers(e.target);
    });
  }

  processMarkers(root) {
    const markers = root.querySelectorAll("[data-reward-unlocked]");
    if (!markers.length) return;

    this.ensureToastHost();

    markers.forEach((el) => {
      const idsCsv = (el.dataset.rewardUnlocked || "").trim();
      if (idsCsv) this.showToast(idsCsv);
      this.fireAnimation();
      el.remove();
    });
  }

  showToast(idsCsv) {
    const div = document.createElement("div");
    div.className = "toast";
    div.style.cssText =
      "background:#fff;border:1px solid var(--border);border-radius:.6rem;" +
      "padding:.6rem .8rem;box-shadow:0 6px 24px rgba(0,0,0,.08);";
    div.innerHTML =
      `<div style="font-weight:700;">ごほうび解放！</div>
       <div style="font-size:.9rem;color:#555;">ID: ${idsCsv}</div>`;
    this.toasts.appendChild(div);
    setTimeout(() => div.remove(), 5000);
  }

  fireAnimation() {
    document.body.classList.add("reward-pulse");
    setTimeout(() => document.body.classList.remove("reward-pulse"), 900);
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

  get toasts() { return document.getElementById("toasts"); }
}