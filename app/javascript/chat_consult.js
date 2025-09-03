// 相談SSEクライアント（新しいQ&Aを先頭に積む）

// --- guard: 多重登録防止（Turboで同一JSが複数回実行されるのをケア）
if (!window.__consultSubmitBound) {
  window.__consultSubmitBound = true;

  let es = null;

  // 小ユーティリティ
  const esc = (s) =>
    String(s).replace(/[&<>"']/g, (ch) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[ch]));

  const appendText = (node, text) => node.insertAdjacentText("beforeend", text);

  // Q&Aブロックを先頭に作る
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

  // 送信ハンドラ（イベント委譲）
  document.addEventListener("submit", (e) => {
    const form = e.target.closest("#consult-form");
    if (!form) return;
    e.preventDefault();

    const input = document.querySelector("#consult-input");
    const q = (input?.value || "").trim();
    if (!q) return;

    const container = document.getElementById("consult_messages");
    const answerEl = container ? prependTurn(container, q) : null;

    const log = document.querySelector("#consult-log") || null;
    if (log) appendText(log, `👤 ${q}\n🤖 `);

    // 既存ストリームがあればクローズ
    try { es && es.close(); } catch (_) {}

    // 正規URLは data-stream-url から
    const base = document.querySelector("#consult[data-stream-url]")?.dataset.streamUrl || "/consult/stream";
    es = new EventSource(`${base}?q=${encodeURIComponent(q)}`);

    es.addEventListener("system", (ev) => {
      // 接続確認イベント（必要ならUIに反映）
      // console.debug("system:", ev.data);
    });

    es.addEventListener("token", (ev) => {
      if (answerEl) answerEl.insertAdjacentText("beforeend", ev.data);
      if (log) appendText(log, ev.data);
    });

    es.addEventListener("heartbeat", () => {
      // ハートビートはログ出力に載せない（無視）
    });

    const finalize = () => {
      if (log) appendText(log, "\n\n");
      try { es && es.close(); } catch (_) {}
      es = null;
      if (container) container.scrollTop = 0;
    };

    es.addEventListener("done", finalize);

    es.onerror = () => {
      if (answerEl) {
        answerEl.insertAdjacentHTML("beforeend", `<div class="text-muted">（接続が中断されました）</div>`);
      }
      if (log) appendText(log, "\n[接続が中断されました]\n\n");
      finalize();
    };

    // 入力クリア
    if (input) input.value = "";
  });

  // ページ離脱時はストリームを閉じる
  document.addEventListener("turbo:before-render", () => { try { es && es.close(); } catch (_) {} });
  window.addEventListener("pagehide", () => { try { es && es.close(); } catch (_) {} });
}