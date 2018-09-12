import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "step", "portfolioSelected" ]

  initialize() {
    this.showStep(0)
  }

  next(event) {
    event.preventDefault();
    this.validateRequiredFields()
    if (this.valid) {
      this.showStep(this.index + 1)
      return false;
    }
  }

  previous(event) {
    event.preventDefault();
    this.showStep(this.index - 1);
    return false;
  }

  goto(event) {
    event.preventDefault();
    this.showStep(parseInt(event.currentTarget.dataset.wizardStep))
    return false;
  }

  selectPortfolio(event) {
    this.portfolioSelectedTarget.value = true.toString()
  }

  private

  showStep(index) {
    this.index = index
    this.stepTargets.forEach((el, i) => {
      el.classList.toggle("is-hidden", index !== i)
    })
  }

  validateRequiredFields() {
    let anyEmpty = false
    let required_field = "required_field_" + this.index;
    this.targets.findAll(required_field).forEach((element) => {
      if (element.tagName === "INPUT") {
        let isEmpty = element.value === ""
        element.classList.toggle("is-danger", isEmpty)
        element.parentElement.classList.toggle("field-with-errors", isEmpty)
        anyEmpty = anyEmpty || isEmpty
      } else if (element.tagName === "SELECT") {
        let isEmpty = element[element.selectedIndex].value === ""
        element.parentElement.classList.toggle("is-danger", isEmpty)
        element.parentElement.classList.toggle("field-with-errors", isEmpty)
        anyEmpty = anyEmpty || isEmpty
      }
    })
    this.valid = !anyEmpty
  }

  get valid() {
    return this.data.valid
  }

  set valid(value) {
    this.data.valid = value
  }
}
