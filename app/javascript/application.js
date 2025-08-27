// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import "@hotwired/turbo-rails"

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