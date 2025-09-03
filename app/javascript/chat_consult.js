// 相談SSEクライアント（新しいQ&Aを先頭に積む + JSONフォールバック）

if (!window.__consultSubmitBound) {
  window.__consultSubmitBound = true;

  let es = null;

  // --- utils ---
  const esc = (s) =>
    String(s).replace(/[&<>"']/g, (ch) => ({
      "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
    }[ch]));

  const appendText = (node, text) => node && node.insertAdjacentText("beforeend", text);

  function prependTurn(container, questionText) {
    const turn = document.createElement("article");
    turn.className = "consult-turn consult-turn--new";
    turn.innerHTML = `
      <div class="consult-q" style="display:flex; gap:.5rem;">
        <span class="avatar" aria-hidden="true">👤</span>
        <div class="bubble">${esc(questionText)}</div>
      </div>
      <div class="consult-a" style="display:flex; gap:.5rem; margin-top:.25rem;">
        <span class="avatar" aria-hidden="true">🤖</span>
        <div class="bubble" data-answer=""></div>
      </div>
    `.trim();
    container.insertBefore(turn, container.firstElementChild || null);
    setTimeout(() => turn.classList.remove("consult-turn--new"), 1200);
    container.scrollTop = 0;
    return turn.querySelector("[data-answer]");
  }

  async function fallbackAsk(q, answerEl, log) {
    try {
      const res = await fetch(`/consult/ask.json?q=${encodeURIComponent(q)}`, {
        headers: { "Accept": "application/json" },
        credentials: "same-origin",
      });
      const json = await res.json();
      const txt = json?.answer || "（回答を取得できませんでした）";
      if (answerEl) answerEl.textContent += txt;
      appendText(log, `\n${txt}\n\n`);
    } catch (e) {
      if (answerEl) {
        answerEl.insertAdjacentHTML("beforeend", `<div class="text-muted">（接続に失敗しました）</div>`);
      }
      appendText(log, "\n[接続に失敗しました]\n\n");
    }
  }

  // --- handler ---
  document.addEventListener("submit", (e) => {
    const form = e.target.closest("#consult-form");
    if (!form) return;
    e.preventDefault();

    const input = document.querySelector("#consult-input");
    const q = (input?.value || "").trim();
    if (!q) return;

    const container = document.getElementById("consult_messages");
    const answerEl  = container ? prependTurn(container, q) : null;
    const log       = document.getElementById("consult-log");
    const streamBox = document.querySelector("#consult[data-stream-url]");
    const base      = streamBox?.dataset.streamUrl || "/consult/stream";

    appendText(log, `👤 ${q}\n🤖 `);
    if (container) container.setAttribute("aria-busy", "true");

    try { es && es.close(); } catch (_) {}

    // SSE 非対応ブラウザは即フォールバック
    if (!window.EventSource) {
      fallbackAsk(q, answerEl, log);
      if (input) input.value = "";
      if (container) container.setAttribute("aria-busy", "false");
      return;
    }

    es = new EventSource(`${base}?q=${encodeURIComponent(q)}`);

    // サーバ側の接続確認イベント（任意）
    es.addEventListener("system", () => { /* no-op */ });

    // 本文トークン
    es.addEventListener("token", (ev) => {
      if (answerEl) answerEl.insertAdjacentText("beforeend", ev.data);
      appendText(log, ev.data);
    });

    // ハートビートは無視
    es.addEventListener("heartbeat", () => { /* no-op */ });

    const finalize = () => {
      appendText(log, "\n\n");
      try { es && es.close(); } catch (_) {}
      es = null;
      if (container) {
        container.scrollTop = 0;
        container.setAttribute("aria-busy", "false");
      }
    };

    // 正常終了
    es.addEventListener("done", finalize);

    // エラー → JSON フォールバック
    es.onerror = () => {
      try { es && es.close(); } catch (_) {}
      fallbackAsk(q, answerEl, log).finally(finalize);
    };

    if (input) input.value = "";
  });

  // ページ離脱時にクリーンアップ
  document.addEventListener("turbo:before-render", () => { try { es && es.close(); } catch (_) {} });
  window.addEventListener("pagehide", () => { try { es && es.close(); } catch (_) {} });
}