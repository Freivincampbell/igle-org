import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "tagsZone", "template", "emptyState"]
  static values  = { url: String, suffix: String, autoSave: { type: Boolean, default: true } }

  connect() {
    this.selected = new Set()
    this.tagsZoneTarget.querySelectorAll("[data-tag-name-input]").forEach(el => {
      if (el.value) this.selected.add(el.value)
    })
    this.updateEmptyState()
    this.boundClickOutside = this.clickOutside.bind(this)
    document.addEventListener("click", this.boundClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside)
    clearTimeout(this._debounce)
    clearTimeout(this._submitTimer)
  }

  search() {
    clearTimeout(this._debounce)
    this._debounce = setTimeout(() => this._doSearch(), 300)
  }

  _doSearch() {
    const q = this.inputTarget.value.trim()
    if (!q) { this.clearResults(); return }
    const params = new URLSearchParams({ q, frame_suffix: this.suffixValue })
    this.resultsTarget.src = `${this.urlValue}?${params}`
  }

  addItem(event) {
    event.preventDefault()
    const name = event.currentTarget.dataset.name?.trim()
    if (!name || this.selected.has(name)) return

    const fragment = this.templateTarget.content.cloneNode(true)
    const root     = fragment.querySelector("[data-catalog-tag]")

    root.querySelectorAll("[data-tag-name]").forEach(el => el.textContent = name)
    root.querySelectorAll("[data-tag-name-input]").forEach(el => el.value = name)
    root.querySelectorAll("[data-tag-flag]").forEach(el => el.value = name)

    const idx = Date.now()
    root.querySelectorAll("[data-tag-level]").forEach(el => {
      el.name = el.name.replace("__IDX__", idx)
    })
    root.querySelectorAll("[data-tag-idx-input]").forEach(el => el.value = idx)

    this.tagsZoneTarget.appendChild(fragment)
    this.selected.add(name)
    this.inputTarget.value = ""
    this.clearResults()
    this.updateEmptyState()
    this._autoSubmit()
  }

  removeTag(event) {
    event.preventDefault()
    const root = event.currentTarget.closest("[data-catalog-tag]")
    const nameInput = root.querySelector("[data-tag-name-input]")
    if (nameInput?.value) this.selected.delete(nameInput.value)
    root.remove()
    this.updateEmptyState()
    this._autoSubmit()
  }

  // Called when a checkbox or select inside a tag changes (offers_service, looking_for_work, level)
  flagChanged() {
    this._autoSubmit()
  }

  keydown(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.resultsTarget.querySelector("[data-action~='click->catalog-search#addItem']")?.click()
    } else if (event.key === "Escape") {
      this.inputTarget.value = ""
      this.clearResults()
    }
  }

  clearResults() {
    this.resultsTarget.innerHTML = ""
    this.resultsTarget.removeAttribute("src")
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) this.clearResults()
  }

  updateEmptyState() {
    if (!this.hasEmptyStateTarget) return
    this.emptyStateTarget.classList.toggle("hidden", this.selected.size > 0)
  }

  _autoSubmit() {
    if (!this.autoSaveValue) return
    clearTimeout(this._submitTimer)
    this._submitTimer = setTimeout(() => {
      this.element.closest("form")?.requestSubmit()
    }, 1500)
  }
}
