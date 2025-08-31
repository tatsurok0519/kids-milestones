// 目的：送信した質問とストリーミング回答を「一番上」に積む（保存はサーバ側仕様どおり）
// - #consult-form を送信すると、新しいQ&Aブロックを #consult_messages の先頭に生成
// - SSE(/consult/stream) の token をそのブロックの回答エリアに追記
// - 旧 #consult-log はフォールバックとして残す（存在すれば同時に追記）

let es = null;

// --- 小ユーティリティ ---
function esc(s) {
  return String(s).replace(/[&<>"']/g, (ch) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
  }[ch]));
}

function ensureLogFallback() {
  let log = document.querySelector("#consult-log");
  if (!log) {
    // フォールバック: 無ければ右下に小さなログ領域を用意（任意）
    log = document.createElement("pre");
    log.id = "consult-log";
    log.style.position = "fixed";
    log.style.right = "12px";
    log.style.bottom = "12px";
    log.style.maxWidth = "40vw";
    log.style.maxHeight = "30vh";
    log.style.overflow = "auto";
    log.style.padding = "8px 10px";
    log.style.background = "rgba(0,0,0,.05)";
    log.style.borderRadius = "8px";
    log.style.fontSize = "12px";
    log.style.whiteSpace = "pre-wrap";
    document.body.appendChild(log);
  }
  return log;
}

function appendText(node, text) {
  node.insertAdjacentText("beforeend", text);
}

// --- Q&Aブロックを先頭に作る ---
function prependTurn(container, questionText) {
  const turn = document.createElement("article");
  turn.className = "consult-turn consult-turn--new";
  // 最低限のマークアップ（必要に応じてクラス名はCSSに合わせて調整OK）
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
  // 軽いハイライトを外す（任意）
  setTimeout(() => turn.classList.remove("consult-turn--new"), 1200);

  // 上端へ寄せる
  container.scrollTop = 0;

  return turn.querySelector('[data-answer]');
}

// --- 送信ハンドラ：一番上に新規ターンを作ってからSSE開始 ---
document.addEventListener("submit", (e) => {
  const form = e.target.closest("#consult-form");
  if (!form) return;
  e.preventDefault();

  const input = document.querySelector("#consult-input");
  const q = (input?.value || "").trim();
  if (!q) return;

  const container = document.getElementById("consult_messages");
  const answerEl = container ? prependTurn(container, q) : null;

  // フォールバックログ（任意）
  const log = document.querySelector("#consult-log") || null;
  if (log) appendText(log, `👤 ${q}\n🤖 `);

  // 既存ストリームがあれば閉じる（連打対策）
  try { es && es.close(); } catch (_) {}

  // GET クエリで接続（SSEはGETのみ）
  es = new EventSource(`/consult/stream?q=${encodeURIComponent(q)}`);

  es.addEventListener("token", (ev) => {
    if (answerEl) {
      answerEl.insertAdjacentText("beforeend", ev.data);
    }
    if (log) appendText(log, ev.data);
  });

  es.addEventListener("done", () => {
    if (answerEl) {
      // 改行を入れたい場合
      // answerEl.insertAdjacentHTML("beforeend", "<br>");
    }
    if (log) appendText(log, "\n\n");
    es.close();
    // 先頭を見せ続ける
    if (container) container.scrollTop = 0;
  });

  es.onerror = () => {
    if (answerEl) {
      answerEl.insertAdjacentHTML("beforeend", `<div class="text-muted">（接続が中断されました）</div>`);
    }
    if (log) appendText(log, "\n[接続が中断されました]\n\n");
    es.close();
  };

  // 入力クリア
  if (input) input.value = "";
});

// === （任意）サブツリー監視：もし他の仕組みが下に追加しても先頭へ寄せる保険 ===
(function keepNewestOnTop() {
  function init() {
    const container = document.getElementById("consult_messages");
    if (!container) return;
    if (container.__observerInstalled) return;
    container.__observerInstalled = true;

    const opts = { childList: true, subtree: true };
    const obs = new MutationObserver((muts) => {
      let bumped = false;
      obs.disconnect();

      for (const m of muts) {
        if (m.type !== "childList") continue;
        m.addedNodes.forEach((node) => {
          if (!(node instanceof Element)) return;
          // 直下の子に正規化
          let top = node;
          while (top && top.parentElement && top.parentElement !== container) {
            top = top.parentElement;
          }
          if (!top || top.parentElement !== container) return;
          if (container.firstElementChild === top) return;

          container.insertBefore(top, container.firstElementChild || null);
          bumped = true;
        });
      }

      obs.observe(container, opts);
      if (bumped) container.scrollTop = 0;
    });

    obs.observe(container, opts);
  }

  document.addEventListener("turbo:load", init);
  document.addEventListener("turbo:render", init);
})();