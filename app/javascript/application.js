// Configure your import map in config/importmap.rb.
// Read more: https://github.com/rails/importmap-rails

import "@hotwired/turbo-rails";
import "controllers";

import "./mobile_nav"
import "photo_preview";
import "chat_consult";

import * as ActiveStorage from "@rails/activestorage";
ActiveStorage.start();

/* ---------------------------
   ユーティリティ
--------------------------- */
function nearestCard(el) { return el?.closest?.(".milestone-card") }

function readToggleFrom(form, submitEvent) {
  // hidden input → FormData → submitter
  const hidToggle = form.querySelector('input[name="toggle"]')?.value
  const hidState  = form.querySelector('input[name="state"]')?.value
  if (hidToggle) return hidToggle
  if (hidState)  return hidState

  try {
    const fd = new FormData(form)
    const v1 = fd.get("toggle")
    const v2 = fd.get("state")
    if (v1) return String(v1)
    if (v2) return String(v2)
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

function isSignedIn() {
  if (typeof window.__SIGNED_IN__ === "undefined") return true
  return !!window.__SIGNED_IN__
}

function isProgressForm(form) {
  if (!(form instanceof HTMLFormElement)) return false
  if (form.matches('form[data-progress-form]')) return true
  try {
    const action = (form.getAttribute("action") || form.action || "")
    if (action.includes("/achievements/upsert")) return true
  } catch(_) {}
  return false
}

/* ---------------------------
   子ども切替（セレクトで child_id を差し替え）
--------------------------- */
document.addEventListener("change", (e) => {
  const sel = e.target?.closest?.("#child-switcher-select")
  if (!sel) return
  const id  = sel.value
  const url = new URL(window.location.href)
  url.searchParams.set("child_id", id)
  window.Turbo?.visit(url.toString())
})

/* ---------------------------
   ヒントの開閉（data-hint-toggle / data-hint-box）
   ※ <details> を使う場合はJS不要。両対応。
--------------------------- */
document.addEventListener("click", (e) => {
  const btn = e.target.closest?.("[data-hint-toggle]")
  if (!btn) return

  let box = null
  const targetId = btn.getAttribute("aria-controls")
  if (targetId) box = document.getElementById(targetId)

  if (!box) {
    const root = btn.closest(".milestone-card") || btn.closest("turbo-frame") || document
    box = root.querySelector("[data-hint-box]")
  }
  if (!box) return

  const willOpen = box.hasAttribute("hidden") || box.hidden === true || box.style.display === "none"
  if (willOpen) {
    box.hidden = false
    box.removeAttribute("hidden")
    box.style.display = ""
  } else {
    box.hidden = true
    box.setAttribute("hidden", "")
    box.style.display = "none"
  }
  btn.setAttribute("aria-expanded", String(willOpen))
})

/* ---------------------------
   進捗トグル（楽観更新＋おためしモード）
--------------------------- */

// 未ログイン: submit を止めて見た目だけ切替
document.addEventListener("submit", (ev) => {
  const form = ev.target
  if (!isProgressForm(form)) return
  if (isSignedIn()) return

  ev.preventDefault()
  const toggle = readToggleFrom(form, ev)
  const card   = nearestCard(form)

  if (!form.dataset.demoToggled) toggleCardUI(card, toggle)
  form.dataset.demoToggled = "1"

  showDemoToast("おためし中：ログインすると進捗が保存されます")
}, true)

// ログイン時: 送信開始で即時反映（Turboが最終状態で上書き）
document.addEventListener("turbo:submit-start", (ev) => {
  const form = ev.target
  if (!isProgressForm(form)) return
  if (!isSignedIn()) return

  const toggle = readToggleFrom(form, ev)
  const card   = nearestCard(form)
  toggleCardUI(card, toggle)
})

// クリック送信パターンの後方互換（未ログインのみ即時反映）
document.addEventListener("click", (e) => {
  const btn  = e.target.closest?.('form[data-progress-form] > button')
  if (!btn) return
  const form = btn.closest('form[data-progress-form]')
  if (!form || isSignedIn()) return

  const toggle = readToggleFrom(form, { submitter: btn })
  const card   = nearestCard(form)
  toggleCardUI(card, toggle)
  form.dataset.demoToggled = "1"
})

/* ---------------------------
   ごほうび：Turbo Stream → カスタムイベント化（互換用）
   ※ レイアウト側プリレンダーでもOK。両対応。
--------------------------- */
document.addEventListener("turbo:before-stream-render", (ev) => {
  const ts = ev.target
  if (!(ts instanceof Element)) return
  const action = ts.getAttribute("action")
  const target = ts.getAttribute("target")
  if (target !== "reward_animator") return
  if (!["update","append","replace"].includes(action)) return

  const tpl = ts.querySelector("template")
  if (!tpl) return

  const div = document.createElement("div")
  div.innerHTML = tpl.innerHTML
  const payload = div.firstElementChild?.getAttribute("data-reward-unlocked") || ""
  const ids = payload.split(",").map(s => parseInt(s, 10)).filter(n => !isNaN(n))
  if (ids.length) document.dispatchEvent(new CustomEvent("reward:unlocked", { detail: { ids } }))
})

/* ---------------------------
   ごほうび：新規解放アイコンをアニメ
--------------------------- */
document.addEventListener("reward:unlocked", (e) => {
  const ids = e.detail?.ids || []
  ids.forEach((id) => {
    const el  = document.getElementById(`reward_icon_${id}`)
    const img = el?.querySelector("img")
    if (!el || !img) return

    el.classList.remove("anim-unlock")
    void el.offsetWidth
    el.classList.add("anim-unlock")

    let pending = 2
    const onEnd = () => {
      if (--pending <= 0) {
        el.classList.remove("anim-unlock")
        el.removeEventListener("animationend", onEnd, true)
        img.removeEventListener("animationend", onEnd, true)
      }
    }
    el.addEventListener("animationend",  onEnd, true)
    img.addEventListener("animationend", onEnd, true)
    setTimeout(() => el.classList.remove("anim-unlock"), 1800)
  })
})

/* ---------------------------
   トースト自動消去（プリレンダー/Stream両対応）
--------------------------- */
function setupToasts() {
  document.querySelectorAll(".toast[data-timeout]").forEach((el) => {
    if (el.__armed) return; el.__armed = true
    const ms = parseInt(el.getAttribute("data-timeout")) || 3000
    setTimeout(() => el.remove(), ms)
  })
}
document.addEventListener("turbo:load",   setupToasts)
document.addEventListener("turbo:render", setupToasts)

/* ---------------------------
   未ログインの初期クリーニング（おためしモード）
--------------------------- */
// app/javascript/application.js（該当箇所）
function demoInitialCleanup() {
  if (isSignedIn()) return
  try { localStorage.removeItem("try_progress_v1") } catch (_) {}
 document.querySelectorAll(".milestone-card").forEach((el) => {
   el.classList.remove("is-working", "is-achieved")
 })
}
document.addEventListener("turbo:load", demoInitialCleanup)
document.addEventListener("turbo:render", demoInitialCleanup)
document.addEventListener("DOMContentLoaded", demoInitialCleanup)