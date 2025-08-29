// シンプルなSSEクライアント：送信→EventSourceで逐次受信
let es = null;

function append(node, text) {
  node.insertAdjacentText("beforeend", text);
}

document.addEventListener("submit", (e) => {
  const form = e.target.closest("#consult-form");
  if (!form) return;
  e.preventDefault();

  const input = document.querySelector("#consult-input");
  const log   = document.querySelector("#consult-log");
  const q     = (input.value || "").trim();
  if (!q) return;

  // 送信ログ
  append(log, `👤 ${q}\n🤖 `);

  // 既存ストリームがあれば閉じる（連打対策）
  try { es && es.close(); } catch (_e) {}

  // GET クエリで接続（SSEはGETのみ）
  es = new EventSource(`/consult/stream?q=${encodeURIComponent(q)}`);

  es.addEventListener("token", (ev) => {
    append(log, ev.data);
  });

  es.addEventListener("done", () => {
    append(log, "\n\n");
    es.close();
  });

  es.onerror = () => {
    append(log, "\n[接続が中断されました]\n\n");
    es.close();
  };

  input.value = "";
});