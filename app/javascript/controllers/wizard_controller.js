import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "step", "portfolioSelected", "donationAmount", "giftAidAmount",
    "giftAidField", "giftAidPostcode", "giftAidFieldset", "giftAidFieldsetVisible"]

  initialize() {
    this.updateGiftAidFieldsVisibility();
    this.updateGiftAidAmount();
    this.showStep(0)
  }

  next(event) {
    event.preventDefault();
    this.validateRequiredFields()

    if (this.hasGiftAidFieldsetVisibleTarget && this.giftAidFieldsetVisibleTarget.checked)
      this.validateGiftAidFields()


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
    this.portfolioSelectedTarget.value = true.toString();
    this.next(event)
  }

  donate(event) {
    event.preventDefault();
    var form = document.getElementById('payment-form');
    this.validateRequiredFields()
    if (this.valid) {
      form.submit();
      return false;
    }
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

  validateGiftAidFields() {
    this.giftAidFieldTargets.forEach((element) => {
      let isEmpty = element.value === ""
      element.classList.toggle("is-danger", isEmpty)
      element.parentElement.classList.toggle("field-with-errors", isEmpty)
      this.valid = this.valid && !isEmpty
    })

    let postcodeRegex = /^([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? [0-9][A-Za-z]{2}|[Gg][Ii][Rr] 0[Aa]{2})$/
    let element = this.giftAidPostcodeTarget
    let isInvalid = !postcodeRegex.test(element.value)
    element.classList.toggle("is-danger", isInvalid)
    element.parentElement.classList.toggle("field-with-errors", isInvalid)
    this.valid = this.valid && !isInvalid
  }

  updateGiftAidAmount() {
    if(this.hasGiftAidFieldsetVisibleTarget)
      this.giftAidAmountTarget.innerText = '£' + this.donationAmountTarget.value * 1.25 + ' ';
  }

  updateGiftAidFieldsVisibility() {
    if(this.hasGiftAidFieldsetVisibleTarget)
      this.giftAidFieldsetTarget.classList.toggle('is-hidden', !this.giftAidFieldsetVisibleTarget.checked);
  }

  get valid() {
    return this.data.valid
  }

  set valid(value) {
    this.data.valid = value
  }
}
