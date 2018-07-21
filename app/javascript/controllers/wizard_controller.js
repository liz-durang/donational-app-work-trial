import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "step" ]

  initialize() {
    this.showStep(0)
  }

  next() {
    this.showStep(this.index + 1)
  }

  previous() {
    this.showStep(this.index - 1)
  }

  showStep(index) {
    this.index = index
    this.stepTargets.forEach((el, i) => {
      el.classList.toggle("is-hidden", index !== i)
    })
  }
}
