import { Controller } from "@hotwired/stimulus"

// Sidebar drawer controller.
//
// Desktop (≥1024px): sidebar is permanently visible (lg:sticky lg:translate-x-0).
//                    Open/close are no-ops; backdrop stays hidden.
// Mobile/tablet (<1024px): sidebar is off-canvas (-translate-x-full).
//                          toggle() slides it in over the page with a backdrop.
export default class extends Controller {
  static targets = ["nav", "backdrop"]

  // Tailwind's "lg" breakpoint
  static LG_BREAKPOINT = 1024

  connect() {
    this._boundClose       = () => this.close()
    this._boundKeydown     = (e) => this._handleKeydown(e)
    this._boundResize      = () => this._handleResize()

    document.addEventListener("turbo:before-visit", this._boundClose)
    document.addEventListener("keydown", this._boundKeydown)
    window.addEventListener("resize", this._boundResize)

    // Initial sync (in case page loads above lg)
    this._syncAriaForViewport()
  }

  disconnect() {
    document.removeEventListener("turbo:before-visit", this._boundClose)
    document.removeEventListener("keydown", this._boundKeydown)
    window.removeEventListener("resize", this._boundResize)
    document.body.classList.remove("overflow-hidden")
  }

  open() {
    if (!this.hasNavTarget || this._isDesktop()) return
    this.navTarget.classList.remove("-translate-x-full")
    this.navTarget.setAttribute("aria-hidden", "false")
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove("hidden")
    }
    document.body.classList.add("overflow-hidden")
  }

  close() {
    if (!this.hasNavTarget) return
    this.navTarget.classList.add("-translate-x-full")
    this.navTarget.setAttribute("aria-hidden", "true")
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.add("hidden")
    }
    document.body.classList.remove("overflow-hidden")
  }

  toggle() {
    if (!this.hasNavTarget) return
    const isOpen = !this.navTarget.classList.contains("-translate-x-full")
    isOpen ? this.close() : this.open()
  }

  // ── private ──

  _isDesktop() {
    return window.innerWidth >= this.constructor.LG_BREAKPOINT
  }

  _handleKeydown(e) {
    if (e.key === "Escape") this.close()
  }

  _handleResize() {
    // If user resizes from mobile-with-drawer-open into desktop range,
    // body still has overflow-hidden — release it and reset drawer state.
    if (this._isDesktop()) {
      this.navTarget.classList.add("-translate-x-full")
      if (this.hasBackdropTarget) this.backdropTarget.classList.add("hidden")
      document.body.classList.remove("overflow-hidden")
    }
    this._syncAriaForViewport()
  }

  _syncAriaForViewport() {
    if (!this.hasNavTarget) return
    if (this._isDesktop()) {
      // On desktop sidebar is always visible: aria-hidden=false, no need to "open"
      this.navTarget.setAttribute("aria-hidden", "false")
    } else {
      // On mobile sidebar starts closed
      const isOpen = !this.navTarget.classList.contains("-translate-x-full")
      this.navTarget.setAttribute("aria-hidden", isOpen ? "false" : "true")
    }
  }
}
