import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["step"]

  initialize() {
    this.showStep(0);
  }

  next(event) {
    event.preventDefault();
    this.validateFields();

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

  private

  showStep(index) {
    this.index = index
    this.stepTargets.forEach((el, i) => {
      el.classList.toggle("is-hidden", index !== i)
    })
  }

  validateFields() {
    // All these functions should be called so that validation messages are displayed (this does not happen if you only use &&)
    let [requiredValid, telephonesValid, emailsValid, customsValid] = [this.validateRequiredFields(), this.validateTelephoneFields(), this.validateEmailAddressFields(), this.customValidations()];

    this.valid = requiredValid && telephonesValid && emailsValid && customsValid
  }

  // Overwrite this function in subclasses to add custom validations.
  customValidations() {
    return true;
  }

  validateRequiredFields() {
    let anyEmpty = false
    let required_field = "required_field_" + this.index;
    this.targets.findAll(required_field).forEach((element) => {
      // This logic will break if we have any conditionally required type[hidden] inputs (radio-select-controller uses hidden inputs).
      if (this.isElementHidden(element) && this.isElementRequiredConditionally(element)) {
        element.parentElement.parentElement.classList.remove("field-with-errors")
        anyEmpty = anyEmpty || false
      } else if (element.type === "checkbox") {
        let isChecked = element.checked
        element.parentElement.parentElement.classList.toggle("field-with-errors", !isChecked)
        anyEmpty = anyEmpty || !isChecked
      } else if (element.tagName === "INPUT") {
        let isEmpty = element.value === "" || element.value === "undefined"
        element.classList.toggle("is-danger", isEmpty)
        element.parentElement.classList.toggle("field-with-errors", isEmpty)
        anyEmpty = anyEmpty || isEmpty
      } else if (element.tagName === "SELECT") {
        let isEmpty = element.selectedIndex === -1 || element[element.selectedIndex].value === "" || element[element.selectedIndex].value === undefined
        element.parentElement.classList.toggle("is-danger", isEmpty)
        element.parentElement.classList.toggle("field-with-errors", isEmpty)
        anyEmpty = anyEmpty || isEmpty
      }
    })

    return !anyEmpty
  }

  validateEmailAddressFields() {
    let anyInvalid = false
    let email_field = "email_field_" + this.index;
    this.targets.findAll(email_field).forEach((element) => {
      let isValid = element.value.match(/^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/)
      element.classList.toggle("is-danger", !isValid)
      element.parentElement.classList.toggle("field-with-errors", !isValid)
      anyInvalid = anyInvalid || !isValid
    })
    return !anyInvalid
  }

  validateTelephoneFields() {
    let anyInvalid = false
    let telephone_field = "telephone_field_" + this.index;
    this.targets.findAll(telephone_field).forEach((element) => {
      let isValid = element.dataset.valid === "true" // Validation is handled by telephone field controller
      anyInvalid = anyInvalid || !isValid
    })
    return !anyInvalid
  }

  isElementHidden(el) {
    // To check this, we check the display property of the element and all its ancestors
    while (el) {
      if (window.getComputedStyle(el).display === 'none') {
        return true;
      }
      el = el.parentElement;
    }
    return false;
  }

  isElementRequiredConditionally(el) {
    // To check this, we check whether any ancestors are a 'hideable' target from conditional-field-controller
    while (el) {
      if (el.dataset.conditionalFieldTarget === 'hideable') {
        return true;
      }
      el = el.parentElement;
    }
    return false;
  }

  get valid() {
    return this.data.valid
  }

  set valid(value) {
    this.data.valid = value
  }
}
