import { Controller } from "@hotwired/stimulus"

// Mismas clases por rol que en church_admin/ministries/_member_row.html.erb
const ROLE_SELECT_CLASSES = {
  leader: ["border-violet-200", "bg-violet-50", "text-violet-700"],
  co_leader: ["border-sky-200", "bg-sky-50", "text-sky-700"],
  member: ["border-slate-200", "bg-slate-50", "text-slate-600"]
}

export default class extends Controller {
  static targets = ["input", "results", "tagsZone", "template", "searchArea", "emptyState", "group"]
  static values = {
    url: String,
    maxSelections: { type: Number, default: 0 }
  }

  connect() {
    this.selected = new Set()
    this.tagsZoneTarget.querySelectorAll("[data-tag-id-input]").forEach((input) => {
      if (input.value) this.selected.add(input.value)
    })
    this.updateEmptyState()
    this.updateSearchAreaVisibility()
    this.updateGroups()
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
    if (q.length < 2) { this.clearResults(); return }
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
    if (avatarEl && color) {
      // Replace bg-* and text-* color classes with the member's color
      avatarEl.className = avatarEl.className
        .replace(/bg-\w+-\d+/g, "")
        .replace(/text-\w+-\d+/g, "")
        .trim() + " " + color
    }

    root.querySelectorAll("[data-tag-meta]").forEach((el) => {
      if (el.name) el.name = el.name.replace(/__ID__/g, publicId)
      if (name) el.setAttribute("aria-label", `Rol de ${name}`)
    })

    const removeButton = root.querySelector("[data-action~='member-search#removeTag']")
    if (removeButton && name) removeButton.setAttribute("aria-label", `Quitar a ${name}`)

    const primaryEl = root.querySelector("[data-tag-primary]")
    if (primaryEl) primaryEl.value = publicId

    this.zoneForRow(root).appendChild(fragment)
    this.selected.add(publicId)

    this.inputTarget.value = ""
    this.clearResults()
    this.updateEmptyState()
    this.updateSearchAreaVisibility()
    this.updateGroups()
    if (this.hasSearchAreaTarget && !this.searchAreaTarget.hidden) this.inputTarget.focus()
  }

  removeTag(event) {
    event.preventDefault()
    const root = event.currentTarget.closest("[data-member-tag]")
    const idInput = root.querySelector("[data-tag-id-input]")
    if (idInput && idInput.value) this.selected.delete(idInput.value)
    root.remove()
    this.updateEmptyState()
    this.updateSearchAreaVisibility()
    this.updateGroups()
  }

  roleChanged(event) {
    const select = event.target
    this.applyRoleStyle(select)
    if (!this.hasGroupTarget) return

    const row = select.closest("[data-member-tag]")
    const zone = this.groupTargets.find((z) => z.dataset.roleGroup === select.value)
    if (!row || !zone || zone.contains(row)) return

    zone.appendChild(row)
    row.classList.remove("animate-fade-in-up")
    void row.offsetWidth // reinicia la animación
    row.classList.add("animate-fade-in-up")
    this.updateGroups()
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

  updateEmptyState() {
    if (!this.hasEmptyStateTarget) return
    this.emptyStateTarget.classList.toggle("hidden", this.selected.size > 0)
  }

  updateSearchAreaVisibility() {
    if (!this.hasSearchAreaTarget) return
    const atMax = this.maxSelectionsValue > 0 && this.selected.size >= this.maxSelectionsValue
    this.searchAreaTarget.hidden = atMax
  }

  // ── Zonas agrupadas por rol (opcionales; solo la vista de ministerios las define) ──

  zoneForRow(row) {
    if (!this.hasGroupTarget) return this.tagsZoneTarget
    const role = row.querySelector("[data-tag-meta]")?.value
    return this.groupTargets.find((z) => z.dataset.roleGroup === role) || this.tagsZoneTarget
  }

  updateGroups() {
    if (!this.hasGroupTarget) return
    this.groupTargets.forEach((zone) => {
      const role = zone.dataset.roleGroup
      const count = zone.querySelectorAll("[data-member-tag]").length

      const countEl = this.element.querySelector(`[data-count-for="${role}"]`)
      if (countEl) countEl.textContent = count

      const emptyEl = this.element.querySelector(`[data-empty-for="${role}"]`)
      if (emptyEl) emptyEl.classList.toggle("hidden", count > 0)
    })
  }

  applyRoleStyle(select) {
    const classes = ROLE_SELECT_CLASSES[select.value]
    if (!classes) return
    Object.values(ROLE_SELECT_CLASSES).flat().forEach((c) => select.classList.remove(c))
    select.classList.add(...classes)
  }
}
