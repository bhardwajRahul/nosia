import { Controller } from "@hotwired/stimulus"

// Shows stdio command fields or http endpoint fields depending on the
// selected MCP transport type.
export default class extends Controller {
  static targets = [ "httpFields", "stdioFields" ]

  connect() {
    this.toggleTransportFields()
  }

  toggleTransportFields() {
    const select = this.element.querySelector('select[name*="transport_type"]')
    const stdio = Boolean(select) && select.value === "stdio"

    this.httpFieldsTarget.classList.toggle("hidden", stdio)
    this.stdioFieldsTarget.classList.toggle("hidden", !stdio)
  }
}
