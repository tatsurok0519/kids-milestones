import { Controller } from "@hotwired/stimulus"

// Show reward toast only once per (user_id, reward_id).
export default class extends Controller {
  static targets = ["toast"]
  static values = { userId: Number, rewardIds: String }

  connect() {
    const user = this.userIdValue || 0
    const ids = (this.rewardIdsValue || "").split(",").filter(Boolean)

    let shouldShow = false
    ids.forEach((id) => {
      const key = `reward:${user}:${id}`
      if (!localStorage.getItem(key)) {
        localStorage.setItem(key, "1")  // 初めてのメダル → 記録
        shouldShow = true
      }
    })

    if (shouldShow && this.hasToastTarget) {
      const tpl = this.toastTarget
      const node = tpl.content
        ? tpl.content.cloneNode(true)
        : document.createRange().createContextualFragment(tpl.innerHTML)
      document.body.appendChild(node) // ← ここで演出（トースト）を実際に表示
    }

    this.element.remove() // マーカーは不要なので掃除
  }
}