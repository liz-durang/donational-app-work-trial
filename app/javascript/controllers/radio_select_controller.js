import { Controller } from "stimulus"

// TODO: Make this component accessible (respond to tabbing)
export default class extends Controller {
  static targets = [ "output", "button" ]

  initialize() {
    if (this.outputTarget.value) {
      this.buttonTargets.forEach(el => {
        el.classList.toggle('is-active', (el.dataset.radioSelectValue == this.outputTarget.value))
      })
    }
  }

  select(event) {
    event.preventDefault();
    this.clearSelection();
    event.currentTarget.classList.add('is-active');
    this.outputTarget.value = event.currentTarget.dataset.radioSelectValue;
  }

  clearSelection(event) {
    this.buttonTargets.forEach(el => el.classList.remove('is-active'))
  }
}
