import { Controller } from "@hotwired/stimulus"

// Opens a modal by element id. Lives on the trigger button because the modal
// usually has its own controller scope (escape-to-close etc.) that does not
// extend to buttons rendered outside it.
export default class extends Controller {
  static values = { target: String }

  open(event) {
    event?.preventDefault()
    const modal = document.getElementById(this.targetValue)
    if (modal) modal.classList.remove("hidden")
  }
}
