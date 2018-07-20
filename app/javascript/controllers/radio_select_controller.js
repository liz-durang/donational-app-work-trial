import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "output" ]

  select() {
    this.clearSelection();
    event.currentTarget.classList.add('is-active');
    this.outputTarget.value = event.currentTarget.dataset['radio-select-value'];
  }

  clearSelection() {
    this.removeClassFromElements('[data-radio-select-value]', 'is-active');
  }

  private

  removeClassFromElements(selector, cssClass) {
    Array.prototype.forEach.call(document.querySelectorAll(selector), (el) =>
      el.classList.remove(cssClass)
    );
  }
}
