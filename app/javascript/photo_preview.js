// シンプルなプレビュー。ActiveStorage不要。
window.previewSelectedImage = function(input, previewId) {
  const img  = document.getElementById(previewId);
  if (!img) return;

  const file = input.files && input.files[0];
  if (!file) {
    // 選択解除時
    img.removeAttribute("src");
    img.style.background = "#f3f4f6";
    return;
  }

  const url = URL.createObjectURL(file);
  img.src = url;
  img.style.background = "transparent";
  img.onload = () => URL.revokeObjectURL(url);

  // 「写真を削除」にチェックがある場合は外す（上書き想定）
  const removeBox = document.querySelector('input[type="checkbox"][name="child[remove_photo]"]');
  if (removeBox) removeBox.checked = false;
};