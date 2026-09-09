import { Controller } from "@hotwired/stimulus"

// Copies the checked MCP server checkboxes into hidden fields on submit, so
// the chat form carries mcp_server_ids[] even though the checkboxes live in
// a collapsible section rendered outside the submitted controls.
export default class extends Controller {
  static targets = [ "hiddenFields" ]

  copy() {
    const checked = document.querySelectorAll('input[name="mcp_server_ids[]"]:checked')

    this.hiddenFieldsTarget.replaceChildren()
    checked.forEach((checkbox) => {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = "mcp_server_ids[]"
      input.value = checkbox.value
      this.hiddenFieldsTarget.appendChild(input)
    })
  }
}
