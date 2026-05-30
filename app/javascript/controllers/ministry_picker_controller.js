import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "tagsZone", "template", "emptyState"]
  static values  = { url: String, autoSave: { type: Boolean, default: true } }

  connect() {
    this.selected = new Set()
    this.tagsZoneTarget.querySelectorAll("[data-tag-id-input]").forEach(el => {
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
    if (q.length < 2) { this.clearResults(); return }
    const params = new URLSearchParams({ q, frame_id: this.resultsTarget.id })
    this.selected.forEach(id => params.append("exclude[]", id))
    this.resultsTarget.src = `${this.urlValue}?${params}`
  }

  addMinistry(event) {
    event.preventDefault()
    const { publicId, name } = event.currentTarget.dataset
    if (!publicId || this.selected.has(publicId)) return

    const fragment = this.templateTarget.content.cloneNode(true)
    const root = fragment.querySelector("[data-ministry-tag]")

    root.querySelectorAll("[data-tag-name]").forEach(el => { el.textContent = name })

    const idInput = root.querySelector("[data-tag-id-input]")
    if (idInput) {
      idInput.value = publicId
      if (idInput.name) idInput.name = idInput.name.replace(/__ID__/g, publicId)
    }

    root.querySelectorAll("[data-tag-meta]").forEach(el => {
      if (el.name) el.name = el.name.replace(/__ID__/g, publicId)
    })

    this.tagsZoneTarget.appendChild(fragment)
    this.selected.add(publicId)
    this.inputTarget.value = ""
    this.clearResults()
    this.updateEmptyState()
    this._autoSubmit()
  }

  removeTag(event) {
    event.preventDefault()
    const root = event.currentTarget.closest("[data-ministry-tag]")
    const idInput = root.querySelector("[data-tag-id-input]")
    if (idInput?.value) this.selected.delete(idInput.value)
    root.remove()
    this.updateEmptyState()
    this._autoSubmit()
  }

  roleChanged() {
    this._autoSubmit()
  }

  keydown(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.resultsTarget.querySelector("[data-action~='click->ministry-picker#addMinistry']")?.click()
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
