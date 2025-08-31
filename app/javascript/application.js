// app/javascript/application.js 
// Configure your import map in config/importmap.rb.
// Read more: https://github.com/rails/importmap-rails

import "@hotwired/turbo-rails"

// 画像のdirect_uploadに必要
import * as ActiveStorage from "@rails/activestorage"
ActiveStorage.start()

// 画像プレビュー用（あなたの既存ファイル）
import "photo_preview"

// 相談SSEクライアント（あなたの既存ファイル）
import "chat_consult"

/* ---------------------------
   小さなユーティリティ
--------------------------- */
function nearestCard(el) {
  return el?.closest?.(".milestone-card")
}

function readToggleFrom(form, submitEvent) {
  // hidden input[name="toggle"] 優先 → FormData → submitterのdata-mode/value
  const hidden = form.querySelector('input[name="toggle"]')?.value
  if (hidden) return hidden

  try {
    const fd = new FormData(form)
    const val = fd.get("toggle")
    if (val) return String(val)
  } catch (_) {}

  const s = submitEvent?.submitter
  return (s && (s.dataset?.mode || s.value)) || null
}

function toggleCardUI(card, toggle) {
  if (!card || !toggle) return
  if (toggle === "working") {
    const on = !card.classList.contains("is-working")
    card.classList.toggle("is-working", on)
    if (on) card.classList.remove("is-achieved")
  } else if (toggle === "achieved") {
    const on = !card.classList.contains("is-achieved")
    card.classList.toggle("is-achieved", on)
    if (on) card.classList.remove("is-working")
  } else if (toggle === "clear") {
    card.classList.remove("is-working", "is-achieved")
  }
}

function showDemoToast(message) {
  let layer = document.getElementById("toasts")
  if (!layer) {
    layer = document.createElement("div")
    layer.id = "toasts"
    layer.style.position = "fixed"
    layer.style.top = "12px"
    layer.style.right = "12px"
    layer.style.zIndex = "9999"
    document.body.appendChild(layer)
  }
  const t = document.createElement("div")
  t.className = "toast demo-toast"
  t.textContent = message
  t.style.marginBottom = "8px"
  t.style.padding = "10px 14px"
  t.style.borderRadius = "8px"
  t.style.boxShadow = "0 4px 16px rgba(0,0,0,.15)"
  t.style.background = "white"
  t.style.fontSize = "14px"
  layer.appendChild(t)
  setTimeout(() => t.remove(), 2500)
}

/* ---------------------------
   子ども切替（セレクト変更でURLの child_id を差し替え）
--------------------------- */
document.addEventListener("change", (e) => {
  const sel = e.target?.closest("#child-switcher-select")
  if (!sel) return
  const id  = sel.value
  const url = new URL(window.location.href)
  url.searchParams.set("child_id", id)
  window.Turbo?.visit(url.toString())
})

/* ---------------------------
   ヒントの開閉（data-hint-toggle / data-hint-box）
   - aria-controls を最優先
   - 見つからなければ同じカード内から探索
   - hidden と display の両方を確実に切り替える
--------------------------- */
document.addEventListener("click", (e) => {
  const btn = e.target.closest?.("[data-hint-toggle]");
  if (!btn) return;

  // 1) aria-controls を最優先
  let box = null;
  const targetId = btn.getAttribute("aria-controls");
  if (targetId) box = document.getElementById(targetId);

  // 2) 見つからなければ同じカード/turbo-frame 内で探索
  if (!box) {
    const root =
      btn.closest(".milestone-card") ||
      btn.closest("turbo-frame") ||
      document;
    box = root.querySelector("[data-hint-box]");
  }
  if (!box) return; // 対象なし

  // 3) 表示/非表示を堅実にトグル
  const willOpen =
    box.hasAttribute("hidden") ||
    box.hidden === true ||
    box.style.display === "none";

  if (willOpen) {
    box.hidden = false;
    box.removeAttribute("hidden");
    box.style.display = ""; // 初期値（CSS任せ）
  } else {
    box.hidden = true;
    box.setAttribute("hidden", "");
    box.style.display = "none";
  }

  btn.setAttribute("aria-expanded", String(willOpen));
});

/* ---------------------------
   進捗トグル（がんばり中/できた！/未着手に戻す）
   - ログイン時: 従来通り送信（Turbo）＋楽観更新
   - 未ログイン: 送信はキャンセルし、見た目だけ切り替える（非保存デモ）
--------------------------- */

// サインイン状態（レイアウトで window.__SIGNED_IN__ を出している想定）
// 未設定の場合は true 扱い（= 安全側：保存をブロックしない）
function isSignedIn() {
  if (typeof window.__SIGNED_IN__ === "undefined") {
    console.warn("[kids-milestones] window.__SIGNED_IN__ が未設定です。ログイン扱いとして動作します。")
    return true
  }
  return !!window.__SIGNED_IN__
}

// A) 未ログインでは submit を捕捉して保存を止める（見た目は切替）
document.addEventListener("submit", (ev) => {
  const form = ev.target
  if (!(form instanceof HTMLFormElement)) return
  if (!form.matches('form[data-progress-form]')) return

  // 既ログインなら通常の送信フローに任せる
  if (isSignedIn()) return

  // --- 未ログイン: 送信せず、見た目だけ切替 ---
  ev.preventDefault()

  const toggle = readToggleFrom(form, ev)
  const card   = nearestCard(form)

  // クリック側で既に切り替えている場合はスキップ（二重反転防止）
  if (!form.dataset.demoToggled) {
    toggleCardUI(card, toggle)
  }
  form.dataset.demoToggled = "1"

  showDemoToast("おためし中：ログインすると進捗が保存されます")
}, true) // capture で早めに横取り

// B) ログイン時の楽観更新（送信開始時に即時反映）
document.addEventListener("turbo:submit-start", (ev) => {
  const form = ev.target
  if (!(form instanceof HTMLFormElement)) return
  if (!form.matches('form[data-progress-form]')) return
  if (!isSignedIn()) return // 未ログインは submit 自体をキャンセルしている

  const toggle = readToggleFrom(form, ev)
  const card   = nearestCard(form)
  toggleCardUI(card, toggle)
})

// C) クリックで送信するパターン（後方互換）
//   - 未ログイン: その場でUIだけ反映（保存なし）
//   - ログイン   : ここでは何もしない（turbo:submit-start に任せる）
document.addEventListener("click", (e) => {
  const btn  = e.target.closest?.('form[data-progress-form] > button')
  if (!btn) return

  const form   = btn.closest('form[data-progress-form]')
  if (!form) return

  if (!isSignedIn()) {
    const toggle = readToggleFrom(form, { submitter: btn })
    const card   = nearestCard(form)
    toggleCardUI(card, toggle)
    form.dataset.demoToggled = "1" // submit 側での二重トグル防止
  }
})

/* ---------------------------
   ごほうび：Turbo Stream → カスタムイベント化
   - reward_animator ターゲットの update/append/replace を捕捉
   - data-reward-unlocked="1,2,3" を読み、reward:unlocked を発火
--------------------------- */
document.addEventListener("turbo:before-stream-render", (ev) => {
  const ts = ev.target
  if (!(ts instanceof Element)) return

  const action = ts.getAttribute("action")
  const target = ts.getAttribute("target")
  if (!target || target !== "reward_animator") return
  if (!["update","append","replace"].includes(action)) return

  const tpl = ts.querySelector("template")
  if (!tpl) return

  const div = document.createElement("div")
  div.innerHTML = tpl.innerHTML
  const payload = div.firstElementChild?.getAttribute("data-reward-unlocked") || ""
  const ids = payload.split(",").map(s => parseInt(s, 10)).filter(n => !isNaN(n))

  if (ids.length) {
    document.dispatchEvent(new CustomEvent("reward:unlocked", { detail: { ids } }))
  }
})

/* ---------------------------
   ごほうび：新規解放イベントでアイコンにアニメ用クラスを付与
--------------------------- */
document.addEventListener("reward:unlocked", (e) => {
  const ids = e.detail?.ids || [];
  ids.forEach((id) => {
    const el  = document.getElementById(`reward_icon_${id}`);
    const img = el?.querySelector("img");
    if (!el || !img) return;

    // リスタート用リセット
    el.classList.remove("anim-unlock");
    void el.offsetWidth;

    el.classList.add("anim-unlock");

    // 両方（wrapper と img）の animationend を待ってから片付け
    let pending = 2;
    const onEnd = () => {
      pending -= 1;
      if (pending <= 0) {
        el.classList.remove("anim-unlock");   // ← 光りっぱなし防止
        el.removeEventListener("animationend", onEnd, true);
        img.removeEventListener("animationend", onEnd, true);
      }
    };
    el.addEventListener("animationend",  onEnd, true);
    img.addEventListener("animationend", onEnd, true);

    // 念のための安全弁（1.8s 後に必ず消す）
    setTimeout(() => el.classList.remove("anim-unlock"), 1800);
  });
});

/* ---------------------------
   トーストの自動消去（Turbo遷移にも対応）
--------------------------- */
function setupToasts() {
  document.querySelectorAll(".toast[data-timeout]").forEach((el) => {
    if (el.__armed) return; el.__armed = true;
    const ms = parseInt(el.getAttribute("data-timeout")) || 3000
    setTimeout(() => el.remove(), ms)
  })
}
document.addEventListener("turbo:load",   setupToasts)
document.addEventListener("turbo:render", setupToasts)

/* ---------------------------
   未ログイン時の初期クリーニング
   - 以前の localStorage 仕様の残骸を消す
   - DOMの .is-working / .is-achieved を初期状態に戻す
--------------------------- */
function demoInitialCleanup() {
  if (isSignedIn()) return
  try { localStorage.removeItem("try_progress_v1") } catch (_) {}
  document.querySelectorAll(".is-working, .is-achieved").forEach((el) => {
    el.classList.remove("is-working", "is-achieved")
  })
}
document.addEventListener("turbo:load", demoInitialCleanup)
document.addEventListener("turbo:render", demoInitialCleanup)