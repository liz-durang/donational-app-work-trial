import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "output", "button" ]

  select() {
    event.preventDefault();
    this.clearSelection();
    event.currentTarget.classList.add('is-active');
    this.outputTarget.value = event.currentTarget.dataset.radioSelectValue;
  }

  clearSelection() {
    this.buttonTargets.forEach(el => el.classList.remove('is-active'))
  }
}
