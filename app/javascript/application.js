// app/javascript/application.js
// Configure your import map in config/importmap.rb.
// Read more: https://github.com/rails/importmap-rails

import "@hotwired/turbo-rails"

// 画像のdirect_uploadに必要
import * as ActiveStorage from "@rails/activestorage"
ActiveStorage.start()

// 画像プレビュー用（あなたの既存ファイル）
import "./photo_preview"

import "./chat_consult"

/* 子ども切替（セレクト変更でURLの child_id を差し替え） */
document.addEventListener("change", (e) => {
  const sel = e.target?.closest("#child-switcher-select")
  if (!sel) return
  const id  = sel.value
  const url = new URL(window.location.href)
  url.searchParams.set("child_id", id)
  window.Turbo?.visit(url.toString())
})

/* ヒントの開閉（data-hint-toggle / data-hint-box） */
document.addEventListener("click", (e) => {
  const btn = e.target.closest("[data-hint-toggle]")
  if (!btn) return

  const root = btn.closest(".milestone-card") || btn.closest("turbo-frame") || document
  const box  = root.querySelector("[data-hint-box]")
  if (!box) return

  const willOpen = box.hasAttribute("hidden")
  if (willOpen) box.removeAttribute("hidden")
  else          box.setAttribute("hidden", "")
  btn.setAttribute("aria-expanded", String(willOpen))
})

/* 楽観的UI更新（がんばり中/できた！/未着手に戻す）
   - _controls.html.erb 側で form[data-progress-form] と hidden_field :toggle
     または button_to の params: { toggle: ... } を出している前提
   - 送信開始時にカードのクラスを即時トグル
   - 最終状態は Turbo Stream の差し替えに任せる */
function nearestCard(el) {
  return el.closest(".milestone-card")
}

document.addEventListener("turbo:submit-start", (ev) => {
  const form = ev.target
  if (!(form instanceof HTMLFormElement)) return
  if (!form.matches('form[data-progress-form]')) return

  const toggle = form.querySelector('input[name="toggle"]')?.value ||
                 new FormData(form).get("toggle")
  const card   = nearestCard(form)
  if (!toggle || !card) return

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
})

// クリックで送信するパターンにも対応（後方互換）
document.addEventListener("click", (e) => {
  const btn  = e.target.closest('form[data-progress-form] > button')
  if (!btn) return

  const form   = btn.closest('form[data-progress-form]')
  const toggle = form?.querySelector('input[name="toggle"]')?.value ||
                 new FormData(form).get("toggle")
  const card   = nearestCard(form)
  if (!toggle || !card) return

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
})