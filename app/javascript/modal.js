// data-modal-open="ID" / data-modal-close="ID" / data-modal-panel="ID" / data-modal-backdrop="ID"
(function(){
  function open(id){
    const panel = document.querySelector(`[data-modal-panel="${id}"]`);
    const backdrop = document.querySelector(`[data-modal-backdrop="${id}"]`);
    if(!panel || !backdrop) return;
    panel.hidden = false;
    backdrop.setAttribute('data-open', 'true');
    // フォーカス移動
    const focusable = panel.querySelector('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
    (focusable || panel).focus({ preventScroll: true });
    document.body.classList.add('nav-open'); // 背景スクロール固定を流用
  }
  function close(id){
    const panel = document.querySelector(`[data-modal-panel="${id}"]`);
    const backdrop = document.querySelector(`[data-modal-backdrop="${id}"]`);
    if(!panel || !backdrop) return;
    panel.hidden = true;
    backdrop.removeAttribute('data-open');
    document.body.classList.remove('nav-open');
  }

  document.addEventListener('click', (e) => {
    const openBtn = e.target.closest('[data-modal-open]');
    if (openBtn) {
      e.preventDefault();
      open(openBtn.getAttribute('data-modal-open'));
      return;
    }
    const closeBtn = e.target.closest('[data-modal-close]');
    if (closeBtn) {
      e.preventDefault();
      close(closeBtn.getAttribute('data-modal-close'));
      return;
    }
    // バックドロップクリックで閉じる
    const bd = e.target.closest('[data-modal-backdrop]');
    if (bd) close(bd.getAttribute('data-modal-backdrop'));
  });

  // ESCで閉じる
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      document.querySelectorAll('[data-modal-panel]').forEach(p => {
        if (!p.hidden) close(p.getAttribute('data-modal-panel'));
      });
    }
  });
})();