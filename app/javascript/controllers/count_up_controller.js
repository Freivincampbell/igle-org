import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["value"]
  static values = { end: Number, duration: { type: Number, default: 1000 } }

  connect() {
    if (this.endValue === 0) return

    const end = this.endValue
    const duration = this.durationValue
    const startTime = performance.now()
    const easeOutQuart = t => 1 - Math.pow(1 - t, 4)

    const tick = now => {
      const progress = Math.min((now - startTime) / duration, 1)
      this.valueTarget.textContent = Math.round(easeOutQuart(progress) * end)
      if (progress < 1) requestAnimationFrame(tick)
    }

    requestAnimationFrame(tick)
  }
}
