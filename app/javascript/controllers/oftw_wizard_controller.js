import WizardController from "./wizard_controller"
import timeZoneCityToCountry from "../constants/timeZoneCityToCountry"
import { until } from "../until.js";

let debounce = require("lodash/debounce");

const countryConfig = {
  'United Kingdom': { currency: 'GBP', locale: 'en-GB', symbol: '£' },
  'Australia': { currency: 'AUD', locale: 'en-AU', symbol: '$' },
  'Canada': { currency: 'CAD', locale: 'en-CA', symbol: '$' },
  'United States': { currency: 'USD', locale: 'en-US', symbol: '$' },
  'default': { currency: 'USD', locale: 'en-US', symbol: '$' }
};
const currencies = [...new Set(Object.values(countryConfig).map(config => config.currency))];

export default class extends WizardController {
  static targets = ["AUDPartnerPortfolios", "CADPartnerPortfolios", "GBPPartnerPortfolios", "USDPartnerPortfolios",
    "amountCents", "amountSummary", "currencySelect", "donationEstimate", "emailAddress",
    "estimatedFutureIncomeCurrency", "firstName", "form", "estimatedFutureIncome", "futurePledgeStart",
    "giftAid", "giftAidFieldset", "giftAidHouseNumber", "giftAidPostcode", "giftAidTitle", "lastName",
    "managedPortfolioHiddenInput", "minimumContributionAmountError",
    "paymentMethodHiddenInput", "paymentOptions", "pledgePercentage", "pledgeStartMonth", "pledgeStartYear",
    "portfolioOption", "portfolioSummary", "previous", "progress", "progressBarColumn", "promptToUseBankAccount",
    "startDateSummary", "summary", "trialDonationAmount", "trialDonationAmountCurrency",
    "wrongCurrencyNotice"]
  static values = {
    campaignSlug: String,
    campaignCurrency: String,
    currencyToPaymentProcessorAccountIdMapping: Object,
    portfolioIdToNameMapping: Object,
    stripeApiKey: String,
    afterReturnFromSuccessfulStripeCheckout: Boolean,
    minimumContributionAmount: Number,
  }

  initialize() {
    super.initialize()
    this.setUpAdditionalTargets()
    this.updateDonationEstimate = debounce(this.updateDonationEstimate, 500).bind(this)
    this.csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    if (this.afterReturnFromSuccessfulStripeCheckoutValue) {
      this.showStep(3)
      this.currencyCodeValue = this.selectedCurrencyCode;
      this.updatePortfolioSummary();
      this.updatePledgeStartSummary()
    } else if (this.campaignCurrencyValue) {
      this.currencySelectTarget.value = this.currencyOptionTargets[this.campaignCurrencyValue].value;
      this.currencyCodeValue = this.campaignCurrencyValue;
      this.resetFieldsOnCurrencyChange();
    } else {
      // Set the default currency after a short wait. This is a trade-off between perceived page load time and trying to
      // avoid the situation where the browser automatically changes the currency select value to a previous input,
      // _after_ we set it to the user location. The problem with this is that the browser-based change doesn't trigger
      // all the functions we need to be triggered by a change in the selected currency. ('oninput'/'onchange' don't pick it up either.)
      // You can get into this state (at least in Chrome?) by selecting a currency from a country other than where your
      // browser is based, proceeding to the Stripe checkout page, and then using the browser's (not Stripe's) back button.
      // This browser-based value change fails to trigger our refreshPortfolioOptions function, and
      // so results in inconsistency between the currency select value and the portfolio options we present.
      this.setDefaultCurrencyOptionByUserLocation = debounce(this.setDefaultCurrencyOptionByUserLocation, 50).bind(this)
      this.setDefaultCurrencyOptionByUserLocation()
    }
  }

  async next(event) {
    event.preventDefault();
    this.validateFields();

    // Since the Stripe redirect takes several seconds, disable button to prevent multiple requests being sent
    this.progressTarget.setAttribute("disabled", "");
    this.progressTarget.innerText = 'Loading';

    // Only redirect to Stripe when the user is navigating forwards through the steps.
    if (this.valid && this.index == 2) {
      this.redirectToStripeCheckoutSession()
    } else if (this.valid && this.index == 1 && this.paymentMethodTargets[this.currencyCodeValue].children.length == 1) {
      // If there's only one payment method, skip the step of choosing the payment method.
      // If that payment method is a type of banking, it will have been selected in the background by
      // selectBankingPaymentMethodByDefault, or if not, we'll select it now by clicking it.
      this.paymentMethodTargets[this.currencyCodeValue].querySelector('[data-radio-select-value]').click()
      // Wait for the click to be processed by the radio select controller.
      await until(() => this.paymentMethodHiddenInputTarget.value !== '')
      this.redirectToStripeCheckoutSession()
    } else {
      this.progressTarget.removeAttribute("disabled");
      this.refreshNavButtons(this.index)
      super.next(event)
    }
  }

  updateDonationEstimate() {
    // Note that when the pledgePercentage button is clicked, it will take some milliseconds to
    // update the corresponding hidden form field. If you're using a decent debounce duration on this
    // function then race conditions will not occur.
    if (this.estimatedFutureIncome && this.pledgePercentageTarget.value) {
      const formattedAmount = this.formatCurrency(this.monthlyDonationEstimate)
      this.donationEstimateTarget.innerText = `Your donation will be ${formattedAmount}/month`
      this.donationEstimateTarget.classList.remove('is-hidden')
      this.amountSummaryTarget.getElementsByClassName('result')[0].innerText = `${formattedAmount}/month`
      this.summaryTarget.innerText = `I pledge ${this.pledgePercentageTarget.value}% of my income to fight extreme poverty.`,
      this.amountCentsTarget.value = this.monthlyDonationEstimate * 100
    }
  }

  updatePledgeStartSummary() {
    if (this.futurePledgeStartTarget.checked && this.pledgeStartMonthTarget.value && this.pledgeStartYearTarget.value) {
      const date = `${this.pledgeStartMonthTarget.value} 15, ${this.pledgeStartYearTarget.value}`
      this.startDateSummaryTarget.getElementsByClassName('result')[0].innerText = date
    }
  }

  updatePortfolioSummary() {
    const selectedPortfolioName = this.managedPortfolioHiddenInputTarget.value ?
      this.portfolioIdToNameMappingValue[this.managedPortfolioHiddenInputTarget.value] : ''

    this.portfolioSummaryTarget.getElementsByClassName('result')[0].innerText = selectedPortfolioName
  }

  async redirectToStripeCheckoutSession() {
    // Tell Stripe.js which account to expect the checkout session to be associated with
    this.stripe = Stripe(this.stripeApiKeyValue, {stripeAccount: this.connectedStripeAccountId}) // the choice of stripe key depends on choice of currency, which dictates the stripe account we want to connect to.

    const response = await fetch("/create-checkout-session", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken
      },
      body: JSON.stringify({
        'campaign_slug': this.campaignSlugValue,
        'partner_id': this.currencySelectTarget.value, // sic: currency selection is underlyingly a choice of partner
        'pledge_form': {
          'partner_id': this.currencySelectTarget.value, // sic: currency selection is underlyingly a choice of partner
          'managed_portfolio_id': this.managedPortfolioHiddenInputTarget.value,
          'estimated_future_annual_income': this.estimatedFutureIncomeTarget.value,
          'pledge_percentage': this.pledgePercentageTarget.value,
          'start_pledge_in_future': this.futurePledgeStartTarget.checked ? 1 : 0, // .value is the wrong attribute for checkboxes
          'start_at_month': this.pledgeStartMonthTarget.value,
          'start_at_year': this.pledgeStartYearTarget.value,
          'uk_gift_aid_accepted': this.giftAidTarget.checked ? 1 : 0, // .value is the wrong attribute for checkboxes
          'title': this.giftAidTitleTarget.value,
          'house_name_or_number': this.giftAidHouseNumberTarget.value,
          'postcode': this.giftAidPostcodeTarget.value,
          'payment_method_id': this.paymentMethodHiddenInputTarget.value,
          'trial_amount_dollars': this.trialDonationAmountTarget.value,
          // TODO: also store the info coming from partner custom donor questions so that people navigating back from a
          // post-Stripe step to a pre-Stripe step would not have to re-enter everything in the post-Stripe questions
        }
      })
    });
    if (!response.ok) {
      throw new Error(`HTTP error. Status: ${response.status}`);
    }

    const contentType = await response.headers.get("Content-Type");
    if (contentType.includes("application/json")) {
      const { sessionUrlForStripeHostedPage } = await response.json();
      window.location.href = sessionUrlForStripeHostedPage;
    } else if (contentType.includes("text/html")) {
      // For debugging / error view. Error info is to be sent to client only in staging environment.
      const text = await response.text();
      document.documentElement.innerHTML = text;
    }
  }

  private

  // Dynamically named target-like elements, generated per currency
  setUpAdditionalTargets() {
    // Read option text directly from HTML, in case formatting changes (currently we're including flag emoji).
    this.currencyOptionTargets = {
      ['GBP']: this.findOptionByText(this.currencySelectTarget, ['GBP', '£']),
      ['AUD']: this.findOptionByText(this.currencySelectTarget, ['AUD', 'A$', 'AU$']),
      ['CAD']: this.findOptionByText(this.currencySelectTarget, ['CAD', 'C$', 'CA$', 'Can$']),
      ['USD']: this.findOptionByText(this.currencySelectTarget, ['USD', '$'], ['A$', 'AU$', 'C$', 'CA$', 'Can$']),
    }
    this.partnerPortfoliosTargets = {};
    for (let currency of currencies) {
      this.partnerPortfoliosTargets[currency] = this.element.querySelector(`[data-oftw-wizard-target=${currency}PartnerPortfolios]`);
    }
    this.paymentMethodTargets = {};
    for (let currency of currencies) {
      this.paymentMethodTargets[currency] = this.element.querySelector(`[data-oftw-wizard-target=${currency}PartnerPaymentOptions]`);
    }
  }

  setDefaultCurrencyOptionByUserLocation() {
    let userCountry;

    if (Intl) {
      const userTimeZone = Intl.DateTimeFormat().resolvedOptions().timeZone;
      const tzArr = userTimeZone.split("/");
      const userCity = tzArr[tzArr.length - 1];
      userCountry = timeZoneCityToCountry[userCity];
    }

    const currencyToSelect = countryConfig[userCountry].currency || countryConfig['default'].currency;
    this.currencySelectTarget.value = this.currencyOptionTargets[currencyToSelect].value;

    this.currencyCodeValue = currencyToSelect;
    this.resetFieldsOnCurrencyChange()
  }

  // Update this.currencyCodeValue to the country's currency code
  currencySelected() {
    let newValue = countryConfig.default.currency;  // fall-back default value
    newValue = this.selectedCurrencyCode;
    this.currencyCodeValue = newValue
    this.resetFieldsOnCurrencyChange()
  }

  refreshPortfolioOptions() {
    currencies.forEach((currency) => {
      this.partnerPortfoliosTargets[currency].classList.toggle('is-hidden', (currency !== this.currencyCodeValue))
    })
  }

  refreshPaymentMethodOptions() {
    currencies.forEach((currency) => {
      this.paymentMethodTargets[currency].classList.toggle('is-hidden', (currency !== this.currencyCodeValue))
    })
  }

  showStep(index) {
    if (index === 5) {
      this.submitForm()
    } else {
      super.showStep(index)
      this.refreshNavButtons(index)
      this.refreshProgressBar(index)
    }
  }

  submitForm() {
    var form = document.getElementById('pledge-form');
    this.validateFields()
    if (this.valid) {
      form.submit();
      return false;
    }
  }

  customValidations() {
    // Close drop-downs to make validation messages visible
    document.querySelectorAll('[data-filterable-dropdown-target="menu"]').forEach((menu) => {
      menu.style.display = "none";
    })
    const pledgeStartValid = this.validatePledgeStartDate();
    const postCodeValid = this.validatePostCodeField();
    const donationAmountValid = this.validateDonationAmount();

    console.log(251)
    console.log(pledgeStartValid, postCodeValid, donationAmountValid)

    return pledgeStartValid && postCodeValid && donationAmountValid
  }

  validatePledgeStartDate() {
    let dateIsValid = true;
    if (!this.isElementHidden(this.futurePledgeStartTarget)) {
      let dateIsPresent = this.pledgeStartMonthTarget.value && this.pledgeStartYearTarget.value
      let dateIsRequired = this.futurePledgeStartTarget.checked
      let dateIsInPast = new Date() > this.getPledgeStartDate()
      if (dateIsRequired && !dateIsPresent) {
        dateIsValid = false
      } else {
        dateIsValid = !(dateIsRequired && dateIsInPast)
      }
      [this.pledgeStartMonthTarget, this.pledgeStartYearTarget].forEach((el) => {
        el.classList.toggle("is-danger", !dateIsValid)
      })
      this.pledgeStartMonthTarget.parentElement.parentElement.classList.toggle("field-with-errors", !dateIsValid)
    }
    return dateIsValid
  }

  validateDonationAmount() {
    let donationAmountIsValid = true;
    if (!this.isElementHidden(this.estimatedFutureIncomeTarget) && (this.monthlyDonationEstimate <= this.minimumContributionAmountValue)) {
      donationAmountIsValid = false;
      this.minimumContributionAmountErrorTarget.innerText = `The minimum monthly donation is ${this.formatCurrency(this.minimumContributionAmountValue)}`
      this.donationEstimateTarget.parentElement.classList.toggle("field-with-errors", !donationAmountIsValid)
    }
    return donationAmountIsValid
  }

  validatePostCodeField() {
    if(this.isElementHidden(this.giftAidPostcodeTarget)) {
      return true;
    } else {
      const postcodeRegex = /^([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? [0-9][A-Za-z]{2}|[Gg][Ii][Rr] 0[Aa]{2})$/
      const postcodeValid = postcodeRegex.test(this.giftAidPostcodeTarget.value)
      this.giftAidPostcodeTarget.classList.toggle("is-danger", !postcodeValid)
      this.giftAidPostcodeTarget.parentElement.classList.toggle("field-with-errors", !postcodeValid)
      return postcodeValid
    }
  }

  refreshNavButtons(index) {
    this.progressTarget.innerText = ['Next ➝', 'Next ➝', 'Next ➝', 'Continue to summary', 'Submit my pledge'][index]
    this.previousTarget.classList.toggle("is-hidden", index == 0);
  }

  updatePromptToUseBankAccount() {
    this.promptToUseBankAccountTarget.classList.toggle("is-hidden", !this.bankingOption)
  }

  // To encourage the use of banking payment over cards, make banking selected by default
  selectBankingPaymentMethodByDefault() {
    const bankingOption = this.bankingOption // the referent of 'this' changes for the setTimeout anonymous function
    if (bankingOption) {
      // Select banking option by default, or only option if there is only one. Triggers radio-select controller method 'select'
      setTimeout(() => {
        // (When doing this on pageload) wait for radio-select controller to have initialized
        bankingOption.click();
      }, 2000);
    }
  }

  refreshProgressBar(index) {
    this.progressBarColumnTargets.forEach((el, i) => {
      el.classList.toggle("blue", i <= index)
      el.classList.toggle("grey", i > index)
    })
  }

  formatCurrency(value) {
    const currencyToLocale = {};

    for (let country in countryConfig) {
      const { currency, locale } = countryConfig[country];
      currencyToLocale[currency] = locale;
    }

    const locale = currencyToLocale[this.currencyCodeValue] || 'en-US';  // Default to English - United States

    const minimumFractionDigits = (parseFloat(value) === parseInt(value)) ? 0 : 2

    return new Intl.NumberFormat(locale, {
      style: 'currency',
      currency: this.currencyCodeValue,
      minimumFractionDigits: minimumFractionDigits,
      maximumFractionDigits: 2
    }).format(value);
  }

  getPledgeStartDate() {
    const monthIndex = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"].indexOf(this.pledgeStartMonthTarget.value);

    return new Date(this.pledgeStartYearTarget.value, monthIndex, 1);
  }

  findOptionByText(selectElement, searchStrings, excludeStrings = []) {
    for (const searchString of searchStrings) {
      const foundOption = [...selectElement.options].find(opt => {
        if (excludeStrings.some(exclude => opt.text.includes(exclude))) {
          return false;
        }
        return opt.text.includes(searchString);
      });

      if (foundOption) {
        return foundOption;
      }
    }
    return null;
  }

  updateEstimatedFutureIncomeCurrency() {
    this.estimatedFutureIncomeCurrencyTarget.innerText = this.currencySymbol;
  }

  updateTrialDonationAmountCurrency() {
    this.trialDonationAmountCurrencyTargets.map((target) => {
      target.innerText = this.currencySymbol;
    })
  }

  updateWrongCurrencyNotice() {
    this.wrongCurrencyNoticeTarget.innerText = this.currencySymbol;
  }

  toggleGiftAidFieldset() {
    if (this.currencyCodeValue === 'GBP') {
      this.giftAidFieldsetTarget.classList.remove('is-hidden')
    } else {
      this.giftAidFieldsetTarget.classList.add('is-hidden')
      Array.from(this.giftAidFieldsetTarget.getElementsByTagName('input')).forEach((el) => {el.value = ""})
    }
  }

  resetFieldsOnCurrencyChange() {
    // The below should only happen when the currency value is set by the user directly operating on the select, or when
    // we operate on it using JS (based on the user location or campaign), since these methods deliberately alter other
    // form fields' values.
    // That is: this should not run when the currency value is set by the view_model in Rails.

    this.managedPortfolioHiddenInputTarget.value = null;
    this.paymentMethodHiddenInputTarget.value = null;
    this.selectBankingPaymentMethodByDefault()
  }

  // Return the payment processor's code for the payment method that is a direct debit (i.e. not card, paypal, etc).
  get bankingOption() {
    return ['us_bank_account', 'bacs_debit', 'acss_debit'].map((value) => {
      return this.paymentMethodTargets[this.currencyCodeValue].querySelector(`[data-radio-select-value='${value}']`)
    }).find(el => el !== null)
  }

  get connectedStripeAccountId() {
    return this.currencyToPaymentProcessorAccountIdMappingValue[this.currencyCodeValue]
  }

  get estimatedFutureIncome() {
    return this.estimatedFutureIncomeTarget.value.match(/\d+/g)?.join('');
  }

  get monthlyDonationEstimate() {
    let estimate = parseFloat(parseFloat(this.estimatedFutureIncome)/12.0) * (parseFloat(this.pledgePercentageTarget.value)/100.0)

    return estimate.toFixed(0)
  }

  get currencySymbol() {
    for (let country in countryConfig) {
      if (countryConfig[country].currency === this.currencyCodeValue) {
        return countryConfig[country].symbol;
      }
    }
  }

  get currencyCodeValue() {
    return this.data.currencyCodeValue;
  }

  get selectedCurrencyCode() {
    for (let currency of currencies) {
      if (this.currencyOptionTargets[currency].selected) {
        return currency;
      }
    }
  }

  set currencyCodeValue(value) {
    this.data.currencyCodeValue = value;
    this.refreshPortfolioOptions()
    this.refreshPaymentMethodOptions()
    this.updateEstimatedFutureIncomeCurrency()
    this.updateTrialDonationAmountCurrency()
    this.updateWrongCurrencyNotice()
    this.updateDonationEstimate()
    this.updatePromptToUseBankAccount()
    this.toggleGiftAidFieldset()
  }
}
