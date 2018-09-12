import { Controller } from "stimulus"

export default class extends Controller {
  remove(event) {
    event.preventDefault()

    if (confirm(this.element.dataset.deleteElementConfirmation)) {
      this.element.parentNode.removeChild(this.element)
    }
  }
}
