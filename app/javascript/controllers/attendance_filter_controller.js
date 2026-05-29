import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="attendance-filter"
export default class extends Controller {
  static targets = ["input", "row", "count", "section", "checkbox"]

  connect() {
    this.updateCount()
  }

  filter() {
    const q = this.inputTarget.value.trim().toLowerCase()
    this.rowTargets.forEach((row) => {
      const name = (row.dataset.memberName || "").toLowerCase()
      row.hidden = q.length > 0 && !name.includes(q)
    })
    this.sectionTargets.forEach((section) => {
      const rows = section.querySelectorAll("[data-attendance-filter-target~='row']")
      const anyVisible = Array.from(rows).some((r) => !r.hidden)
      section.hidden = !anyVisible
    })
  }

  updateCount() {
    if (!this.hasCountTarget) return
    this.countTarget.textContent = this.checkboxTargets.filter((c) => c.checked).length
  }
}
