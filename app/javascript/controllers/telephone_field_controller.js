import { Controller } from "stimulus"
import intlTelInput from 'intl-tel-input';

let debounce = require("lodash/debounce");


const currencyToCountryCode = {
  'GBP': 'gb',
  'AUD': 'au',
  'CAD': 'ca',
  'USD': 'us',
}
const errorMap = ["This number is invalid", "The country code is invalid", "This number is too short", "This number is too long", "This number is invalid"];

export default class extends Controller {
  static targets = ["input", "hiddenInput"]
  static values = { currencyCode: String }

  initialize () {
    // Find out if this element is visible.
    if (this.inputTarget.closest('is-hidden') ) {
      // Watch the element for when it becomes visible. When the class changes to
      // no longer contain 'is-hidden', call this controller's initialize function again.
      const observer = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
          if (mutation.target.classList.contains('is-hidden')) {
            return
          }
          observer.disconnect()
          this.initialize()
        })
      })
    }

    this.iti = intlTelInput(this.inputTarget, {
      utilsScript: "https://cdn.jsdelivr.net/npm/intl-tel-input@18.2.1/build/js/utils.js",
      initialCountry: currencyToCountryCode[this.currencyCodeValue] || 'us',
      preferredCountries: ['gb', 'au', 'ca', 'us'],
      separateDialCode: true,
    })
    this.validate = debounce(this.validate, 500).bind(this)
  }

  onChange() {
    this.removeLetters()
    this.validate()
    this.populateHiddenField()
  }

  private

  removeLetters() {
    this.inputTarget.value = this.inputTarget.value.replace(/[a-zA-Z]/g, "")
  }

  validate () {
    if (this.inputTarget.value.trim()) {
      const valid = this.iti.isValidNumber()
      const errorCode = this.iti.getValidationError();
      this.getErrorMessageElement().innerHTML = valid ? 'This field is required' : errorMap[errorCode];
      this.inputTarget.classList.toggle("is-danger", !valid)
      this.inputTarget.parentElement.classList.toggle("field-with-errors", !valid)
      this.inputTarget.dataset.valid = valid
    } else {
      this.inputTarget.classList.remove("is-danger")
      this.inputTarget.parentElement.classList.remove("field-with-errors")
      this.inputTarget.dataset.valid = true
      // Revert message which is not currently displayed to its default value so that, if the field is required,
      // this message is the one displayed (rather than something left over from a validation check)
      this.getErrorMessageElement().innerHTML = 'This field is required';
    }
  }

  populateHiddenField () {
    const number = this.iti.getNumber() // Get the full international number including country code.
    const hiddenField = this.hiddenInputTarget
    hiddenField.value = `${number}`
  }

  getErrorMessageElement() {
    return this.inputTarget.parentElement.parentElement.querySelector(".display-when-errors")
  }
}
