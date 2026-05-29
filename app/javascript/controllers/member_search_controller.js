import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="member-search"
export default class extends Controller {
  static targets = ["input", "results", "tagsZone", "template", "searchArea"]
  static values = {
    url: String,
    maxSelections: { type: Number, default: 0 }
  }

  connect() {
    this.selected = new Set()
    this.tagsZoneTarget.querySelectorAll("[data-tag-id-input]").forEach((input) => {
      if (input.value) this.selected.add(input.value)
    })
    this.updateSearchAreaVisibility()
    this.boundClickOutside = this.clickOutside.bind(this)
    document.addEventListener("click", this.boundClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside)
    if (this.debounceTimer) clearTimeout(this.debounceTimer)
  }

  search() {
    if (this.debounceTimer) clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => this.performSearch(), 300)
  }

  performSearch() {
    const q = this.inputTarget.value.trim()
    if (q.length < 2) {
      this.clearResults()
      return
    }
    const params = new URLSearchParams()
    params.set("q", q)
    params.set("frame_id", this.resultsTarget.id)
    this.selected.forEach((id) => params.append("exclude[]", id))
    this.resultsTarget.src = `${this.urlValue}?${params.toString()}`
  }

  addMember(event) {
    event.preventDefault()
    const { publicId, name, initials, color } = event.currentTarget.dataset
    if (!publicId || this.selected.has(publicId)) return

    const fragment = this.templateTarget.content.cloneNode(true)
    const root = fragment.querySelector("[data-member-tag]")

    root.querySelector("[data-tag-id-input]").value = publicId

    const nameEl = root.querySelector("[data-tag-name]")
    if (nameEl) nameEl.textContent = name

    const initialsEl = root.querySelector("[data-tag-initials]")
    if (initialsEl) initialsEl.textContent = initials

    const avatarEl = root.querySelector("[data-tag-avatar]")
    if (avatarEl && color) avatarEl.className = avatarEl.className.replace(/bg-\S+/, color)

    root.querySelectorAll("[data-tag-meta]").forEach((el) => {
      if (el.name) el.name = el.name.replace("__ID__", publicId)
    })

    const primaryEl = root.querySelector("[data-tag-primary]")
    if (primaryEl) primaryEl.value = publicId

    this.tagsZoneTarget.appendChild(fragment)
    this.selected.add(publicId)

    this.inputTarget.value = ""
    this.clearResults()
    this.updateSearchAreaVisibility()
    if (this.hasSearchAreaTarget && !this.searchAreaTarget.hidden) this.inputTarget.focus()
  }

  removeTag(event) {
    event.preventDefault()
    const root = event.currentTarget.closest("[data-member-tag]")
    const idInput = root.querySelector("[data-tag-id-input]")
    if (idInput && idInput.value) this.selected.delete(idInput.value)
    root.remove()
    this.updateSearchAreaVisibility()
  }

  keydown(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      const first = this.resultsTarget.querySelector("[data-action~='click->member-search#addMember']")
      if (first) first.click()
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

  updateSearchAreaVisibility() {
    if (!this.hasSearchAreaTarget) return
    const atMax = this.maxSelectionsValue > 0 && this.selected.size >= this.maxSelectionsValue
    this.searchAreaTarget.hidden = atMax
  }
}
