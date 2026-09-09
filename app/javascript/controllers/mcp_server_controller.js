import { Controller } from "@hotwired/stimulus"

// Switches between the tab panes on the MCP server detail page.
export default class extends Controller {
  showTab(event) {
    event.preventDefault()

    this.element.querySelectorAll(".mcp-tab").forEach((tab) => {
      tab.classList.remove("active", "n-tab-active")
      tab.classList.add("n-tab")
    })
    event.currentTarget.classList.add("active", "n-tab-active")
    event.currentTarget.classList.remove("n-tab")

    this.element.querySelectorAll(".tab-pane").forEach((pane) => {
      pane.classList.add("hidden")
    })

    const pane = document.getElementById(`${event.currentTarget.dataset.tab}-tab`)
    if (pane) pane.classList.remove("hidden")
  }
}
