import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { duration: { type: Number, default: 4000 } }

  connect() {
    if (this.durationValue > 0) {
      this._timer = setTimeout(() => this.dismiss(), this.durationValue)
    }
  }

  disconnect() {
    this._clearTimer()
  }

  dismiss() {
    this._clearTimer()
    this.element.style.transition = "opacity 200ms ease, transform 200ms ease, max-height 200ms ease"
    this.element.style.opacity = "0"
    this.element.style.transform = "translateX(0.5rem)"
    this.element.style.maxHeight = "0"
    this.element.style.overflow = "hidden"
    setTimeout(() => this.element.remove(), 210)
  }

  _clearTimer() {
    if (this._timer) { clearTimeout(this._timer); this._timer = null }
  }
}
