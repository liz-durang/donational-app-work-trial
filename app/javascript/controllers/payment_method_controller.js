import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "selectState", "inputState", "country" ]

  displayState() {
    event.preventDefault()
    this.clearSelection()
    if (event.currentTarget.value === "US") {
      this.selectStateTarget.classList.remove('is-hidden')
    } else {
      this.inputStateTarget.classList.remove('is-hidden')
    }
  }

  clearSelection() {
    this.selectStateTarget.classList.add('is-hidden')
    this.inputStateTarget.classList.add('is-hidden')
  }
}
