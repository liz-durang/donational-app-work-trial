import WizardController from "./wizard_controller"

export default class extends WizardController {
  static targets = [ "portfolioSelected", "donationAmount", "giftAidAmount",
  "giftAidField", "giftAidPostcode", "giftAidFieldset", "giftAidFieldsetVisible",
  "paymentOptionPlaid", "paymentOptionCard", "feesDetails" ]

  initialize() {
    this.updateGiftAidFieldsVisibility();
    this.updateGiftAidAmount();
    this.markFirstAsDefault();
    super.initialize();
  }

  next(event) {
    // Donation step
    if (this.valid && this.index == 2)
      this.validateMinimumDonationAmount()

    if (this.hasGiftAidFieldsetVisibleTarget && this.giftAidFieldsetVisibleTarget.checked)
      this.validateGiftAidFields()

    super.next(event)
  }

  selectPortfolio(event) {
    this.portfolioSelectedTarget.value = true.toString();
  }

  markFirstAsDefault() {
    const radioButtons = document.getElementsByName('campaign_contribution[managed_portfolio_id]');
    if (radioButtons.length > 0) {
      radioButtons.item(0).checked = true;
      this.portfolioSelectedTarget.value = true.toString();
    }
  }

  setFeeDetailsLabel() {
    var amount = document.getElementsByName("campaign_contribution[amount_dollars]")[0].value
    var frequency = document.getElementsByName("campaign_contribution[frequency]")[0].value

    var numTimesPerYear = {
      'annually': 1,
      'once': 1,
      'quarterly': 4,
      'monthly': 12
    }

    var expectedPlaidFees = numTimesPerYear[frequency] * Math.min(5, 0.008 * amount);
    var expectedCardFees = numTimesPerYear[frequency] * (0.3 + (0.022 * amount));

    var label = "Stripe charges up to 4x higher fees for credit card donations. By using Plaid, you're donating "
    label += `$${Math.round(expectedCardFees - expectedPlaidFees)} `
    label += "more every year. Please use Plaid if you can (you can always change your payment method after signing up)."

    this.feesDetailsTarget.innerText = label;
  }

  donate(event) {
    event.preventDefault();
    var form = document.getElementById('payment-form');
    this.validateFields()
    if (this.valid) {
      form.submit();
      return false;
    }
  }

  private

  validateMinimumDonationAmount() {
    let donationAmount = parseInt(this.donationAmountTarget.value)
    let minimumDonationAmount = parseInt(this.donationAmountTarget.dataset.minimumDonationAmount)
    let isValid = donationAmount >= minimumDonationAmount
    this.donationAmountTarget.classList.toggle("is-danger", !isValid)
    this.donationAmountTarget.parentElement.classList.toggle("field-with-validation-errors", !isValid)
    this.valid = this.valid && isValid
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

  showCardPayment() {
    this.paymentOptionCardTarget.classList.toggle('is-hidden', false)
  }
}
