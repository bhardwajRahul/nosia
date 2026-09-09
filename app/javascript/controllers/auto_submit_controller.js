import { Controller } from "@hotwired/stimulus"

// Submits the enclosing form on demand — used by filter toolbars whose
// selects should refresh results immediately.
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
