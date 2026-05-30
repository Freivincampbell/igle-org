import { Controller } from "@hotwired/stimulus"

const BADGE_STATES = {
  checking: {
    text: "⟳ Verificando...",
    classes: "text-violet-700 bg-violet-50 border border-violet-200"
  },
  available: {
    text: "✓ Disponible",
    classes: "text-green-700 bg-green-50 border border-green-200"
  },
  taken: {
    text: "✗ Ya está en uso",
    classes: "text-red-700 bg-red-50 border border-red-200"
  },
  invalid: {
    text: "✗ Formato inválido",
    classes: "text-red-700 bg-red-50 border border-red-200"
  },
  error: {
    text: "⚠ No se pudo verificar",
    classes: "text-yellow-700 bg-yellow-50 border border-yellow-200"
  }
}

export default class extends Controller {
  static targets = ["input", "badge", "urlHint"]
  static values = { checkUrl: String, baseUrl: String }

  connect() {
    this.debounceTimer = null
    this.currentFetchController = null
    // Mostrar el URL hint si ya hay un slug guardado al cargar la página
    const current = this.inputTarget.value.trim()
    if (current) this.#updateUrlHint(current)
  }

  disconnect() {
    if (this.debounceTimer) clearTimeout(this.debounceTimer)
    if (this.currentFetchController) this.currentFetchController.abort()
  }

  sanitize() {
    const raw = this.inputTarget.value
    const clean = raw
      .toLowerCase()
      .replace(/[^a-z0-9\s-]/g, "")
      .replace(/\s+/g, "-")
      .replace(/-+/g, "-")
      .replace(/^-+|-+$/g, "")

    if (this.inputTarget.value !== clean) {
      this.inputTarget.value = clean
    }

    this.#updateUrlHint(clean)

    if (!clean) {
      this.#hideBadge()
      return
    }

    this.#showBadge("checking")
    if (this.debounceTimer) clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => this.#checkAvailability(clean), 500)
  }

  #updateUrlHint(slug) {
    if (!this.hasUrlHintTarget) return
    if (slug) {
      this.urlHintTarget.textContent = `🔗 ${this.baseUrlValue}/c/${slug}`
      this.urlHintTarget.classList.remove("hidden")
    } else {
      this.urlHintTarget.classList.add("hidden")
    }
  }

  #showBadge(state) {
    if (!this.hasBadgeTarget) return
    const { text, classes } = BADGE_STATES[state]
    const badge = this.badgeTarget
    badge.className = `text-xs font-medium rounded-full px-2 py-0.5 ${classes}`
    badge.textContent = text
    badge.classList.remove("hidden")
  }

  #hideBadge() {
    if (this.hasBadgeTarget) this.badgeTarget.classList.add("hidden")
  }

  async #checkAvailability(slug) {
    if (this.currentFetchController) this.currentFetchController.abort()
    this.currentFetchController = new AbortController()
    try {
      const url = new URL(this.checkUrlValue, window.location.origin)
      url.searchParams.set("slug", slug)
      const response = await fetch(url.toString(), {
        signal: this.currentFetchController.signal,
        headers: { Accept: "application/json" }
      })
      if (!response.ok) { this.#showBadge("error"); return }
      const data = await response.json()
      if (data.available) {
        this.#showBadge("available")
      } else {
        this.#showBadge(data.reason === "invalid_format" ? "invalid" : "taken")
      }
    } catch (err) {
      if (err.name === "AbortError") return
      this.#showBadge("error")
    }
  }
}
