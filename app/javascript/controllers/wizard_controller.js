import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "step" ]

  initialize() {
    this.showStep(0)
  }

  next() {
    event.preventDefault();
    this.showStep(this.index + 1)
    return false;
  }

  previous() {
    event.preventDefault();
    this.showStep(this.index - 1);
    return false;
  }

  goto() {
    event.preventDefault();
    this.showStep(parseInt(event.currentTarget.dataset['wizard-step']))
    return false;
  }

  private

  showStep(index) {
    this.index = index
    this.stepTargets.forEach((el, i) => {
      el.classList.toggle("is-hidden", index !== i)
    })
  }
}
