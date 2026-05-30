import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    this._debounce = null
  }

  disconnect() {
    clearTimeout(this._debounce)
  }

  search(event) {
    clearTimeout(this._debounce)
    // Preserve cursor position and full value across frame updates
    const input = event.currentTarget
    const value = input.value
    const selStart = input.selectionStart
    const selEnd = input.selectionEnd

    this._pendingCursor = { selStart, selEnd }
    this._debounce = setTimeout(() => {
      this.element.requestSubmit()
    }, 400)
  }

  filter() {
    clearTimeout(this._debounce)
    this.element.requestSubmit()
  }
}
