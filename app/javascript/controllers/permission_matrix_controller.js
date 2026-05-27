import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  apply(event) {
    const actions = (event.currentTarget.dataset.permissionActions || "").split(",").filter(Boolean)
    const moduleSection = event.currentTarget.closest("[data-permission-module]")

    moduleSection.querySelectorAll("input[type='checkbox']:not(:disabled)").forEach((checkbox) => {
      checkbox.checked = actions.includes(checkbox.dataset.permissionActionKey)
    })
  }
}
