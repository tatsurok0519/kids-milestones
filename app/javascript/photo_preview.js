(() => {
  "use strict";

  // --- ヘルパ：プレビュー対象の <img> を見つける ---
  function findPreviewImage(input, explicitTarget) {
    // 1) 呼び出し時に Id 文字列が来た場合（互換）
    if (explicitTarget && typeof explicitTarget === "string") {
      return document.getElementById(explicitTarget) || null;
    }

    // 2) data-preview-target を参照（id でも CSS セレクタでもOK）
    let sel = input.dataset.previewTarget;
    if (!sel) return null;

    // 先に同一フォーム内を優先して探索
    const root = input.closest("form") || document;

    // idっぽい（英数字と-_のみ）なら # を補う
    if (!/^[#.\[]/.test(sel) && /^[A-Za-z0-9_-]+$/.test(sel)) {
      sel = `#${sel}`;
    }
    return root.querySelector(sel) || document.querySelector(sel) || null;
  }

  // --- ヘルパ：プレビューを更新/クリア ---
  function setPreview(img, file, placeholderBg) {
    if (!(img instanceof HTMLImageElement)) return;

    // 既存の ObjectURL を片付けるために、前回URLを dataset に保持
    const prevUrl = img.dataset.objectUrl;
    if (prevUrl) {
      try { URL.revokeObjectURL(prevUrl); } catch (_) {}
      delete img.dataset.objectUrl;
    }

    if (file) {
      const url = URL.createObjectURL(file);
      img.src = url;
      img.style.background = "transparent";
      img.dataset.objectUrl = url;
      img.onload = () => {
        try { URL.revokeObjectURL(url); } catch (_) {}
        delete img.dataset.objectUrl;
      };
    } else {
      // クリア
      img.removeAttribute("src");
      img.style.background = placeholderBg || "#f3f4f6";
    }
  }

  // --- メイン：input[file] の変更を反映 ---
  function updateFromInput(input, explicitTarget) {
    const img = findPreviewImage(input, explicitTarget);
    if (!img) return;

    const [file] = (input.files || []);
    const ph = input.dataset.placeholderBg || img.dataset.placeholderBg;
    setPreview(img, file || null, ph);

    // 「写真を削除」を自動で外す（上書きとみなす）
    const removeBox = input
      .closest("form")
      ?.querySelector('input[type="checkbox"][name$="[remove_photo]"]');
    if (removeBox && file) removeBox.checked = false;
  }

  // --- イベント委譲（自動バインド）---
  // data-preview-target を持つ <input type="file"> に反応
  document.addEventListener("change", (e) => {
    const t = e.target;
    if (t instanceof HTMLInputElement && t.type === "file" && t.dataset.previewTarget) {
      updateFromInput(t);
    }
  });

  // 「写真を削除」にチェックしたらプレビューを消す
  document.addEventListener("change", (e) => {
    const box = e.target;
    if (!(box instanceof HTMLInputElement)) return;
    if (box.type !== "checkbox") return;
    if (!/\[remove_photo\]$/.test(box.name)) return;

    const form = box.closest("form") || document;
    const fileInput = form.querySelector('input[type="file"][data-preview-target]');
    if (!fileInput) return;

    const img = findPreviewImage(fileInput);
    if (!img) return;

    if (box.checked) {
      const ph = fileInput.dataset.placeholderBg || img.dataset.placeholderBg;
      setPreview(img, null, ph);
      // file 選択もクリア
      fileInput.value = "";
    }
  });

  // --- Turbo 互換：イベント委譲なので特別な再バインド不要だが、
  //     直接呼び出したい人向けにグローバル関数を残す ---
  window.previewSelectedImage = function(input, previewId) {
    if (!(input instanceof HTMLInputElement)) return;
    updateFromInput(input, previewId);
  };
})();