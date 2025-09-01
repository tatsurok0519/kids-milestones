(() => {
  function ack(ids){
    if(!ids.length) return;
    const token = document.querySelector('meta[name="csrf-token"]')?.content;
    fetch("/rewards/ack", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": token },
      body: JSON.stringify({ ids })
    }).catch(() => {});
  }

  // 即時解放（Turbo Streamのトースト）でもアイコンを光らせる
  document.addEventListener("reward:unlocked", (e) => {
    const ids = Array.from(e.detail?.ids || []);
    ids.forEach(id => {
      const el = document.querySelector(`.reward-icon[data-reward-id="${id}"]`);
      if (el) el.classList.add("anim-unlock");
    });
  });

  // ページ表示時（ダッシュボードに来たら）未視聴を再生してACK
  const fire = () => {
    const ids = Array.from(window.UNSEEN_REWARD_IDS || []);
    if (!ids.length) return;

    const shown = [];
    ids.forEach(id => {
      const el = document.querySelector(`.reward-icon[data-reward-id="${id}"]`);
      if (el) {
        el.classList.add("anim-unlock");
        shown.push(id);
      }
    });

    // アイコンが見つかったものだけACK（見つからないIDは次回に持ち越し）
    if (shown.length) {
      // 任意：同時にトースト演出も再生したいなら以下のイベントを投げる
      document.dispatchEvent(new CustomEvent("reward:unlocked", { detail: { ids: shown } }));
      ack(shown);
    }
  };

  document.addEventListener("turbo:load", fire);
  document.addEventListener("DOMContentLoaded", fire);
})();