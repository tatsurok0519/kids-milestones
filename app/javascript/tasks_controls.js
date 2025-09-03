(function () {
  function applyTurboStream(htmlText) {
    const doc = new DOMParser().parseFromString(htmlText, "text/html");
    const streams = doc.querySelectorAll("turbo-stream");
    streams.forEach((ts) => {
      const action = ts.getAttribute("action");
      const target = ts.getAttribute("target");
      const tmpl = ts.querySelector("template");
      if (!action || !target || !tmpl) return;
      const html = tmpl.innerHTML.trim();
      const el = document.getElementById(target);
      if (!el) return;
      if (action === "replace")      el.outerHTML = html;
      else if (action === "update")  el.innerHTML = html;
      else if (action === "append")  el.insertAdjacentHTML("beforeend", html);
      else if (action === "prepend") el.insertAdjacentHTML("afterbegin", html);
    });
  }

  document.addEventListener("submit", async (e) => {
    const form = e.target.closest('form[data-remote-ach="1"]');
    if (!form) return;
    e.preventDefault();

    const fd = new FormData(form);
    try {
      const res = await fetch(form.action, {
        method: (form.getAttribute("method") || "post").toUpperCase(),
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "text/vnd.turbo-stream.html"
        },
        body: fd,
        credentials: "same-origin",
      });
      const text = await res.text();
      if (window.Turbo?.renderStreamMessage) {
        Turbo.renderStreamMessage(text);
      } else {
        applyTurboStream(text);
      }
    } catch (err) {
      console.error("[ach controls] fetch failed:", err);
    }
  });
})();