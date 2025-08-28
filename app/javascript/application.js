// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import "@hotwired/turbo-rails"
import "./photo_preview"

// これが無いと direct_upload が動きません
import * as ActiveStorage from "@rails/activestorage"
ActiveStorage.start()

document.addEventListener("turbo:load", () => {
  const sel = document.getElementById("child-switcher-select");
  if (!sel) return;
  sel.addEventListener("change", (e) => {
    const id = e.target.value;
    const url = new URL(window.location.href);
    url.searchParams.set("child_id", id);
    window.Turbo?.visit(url.toString());
  });
});

document.addEventListener("click", (e) => {
  // button_to が作る form[data-progress-form] のボタンか？
  const btn = e.target.closest('form[data-progress-form] > button');
  if (!btn) return;

  const form = btn.closest('form[data-progress-form]');
  const toggle = form.querySelector('input[name="toggle"]')?.value;
  const card = btn.closest('.milestone-card');
  if (!card || !toggle) return;

  if (toggle === 'working') {
    const on = !card.classList.contains('is-working');
    card.classList.toggle('is-working', on);
    if (on) card.classList.remove('is-achieved');
  } else if (toggle === 'achieved') {
    const on = !card.classList.contains('is-achieved');
    card.classList.toggle('is-achieved', on);
    if (on) card.classList.remove('is-working');
  }
});