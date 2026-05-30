import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["nav", "backdrop"]

  open() {
    this.navTarget.classList.remove("-translate-x-full")
    this.backdropTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.navTarget.classList.add("-translate-x-full")
    this.backdropTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  toggle() {
    const isOpen = !this.navTarget.classList.contains("-translate-x-full")
    isOpen ? this.close() : this.open()
  }

  // Cerrar cuando se navega (Turbo drive)
  connect() {
    this._boundClose = () => this.close()
    document.addEventListener("turbo:before-visit", this._boundClose)
  }

  disconnect() {
    document.removeEventListener("turbo:before-visit", this._boundClose)
  }
}
