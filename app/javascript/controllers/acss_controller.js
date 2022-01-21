import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "submit", "stripeKey", "stripeAccount", "acssInfo", "paymentMethodField", "submissionField",
                     "accountHolder", "email", "frequency", "startMonth", "startYear", "trial", "customerId",
                     "partnerId" ]

  initialize() {}

  setUp() {
    // Stop when ACSS has already been set up
    if (this.paymentMethodField.val())
      return;

    var acssButton = $(this.submitTarget);
    acssButton.addClass("is-loading");

    this.acssInfoTarget.innerHTML = this.acssIntervalDescription(this.frequency, this.startMonth, this.startYear, this.trial);

    // Set account holder name placeholder on campaign page
    if (this.firstName)
      this.accountHolderTarget.value = `${this.firstName} ${this.lastName}`;

    $.post("/get_acss_client_secret", this.paymentDetails, this.callback.bind(this));
  }

  callback(data) {
    var controller = this;
    var acssButton = $(this.submitTarget);
    var clientSecret = data["client_secret"];;
    this.customerIdTarget.value = data["customer_id"];
    acssButton.removeClass("is-loading");
    acssButton.prop("disabled", false);
    acssButton.unbind("click");

    acssButton.on("click", function(event) {
      event.preventDefault();
      if (controller.paymentMethodField.val())
        return;

      acssButton.addClass("is-loading");
      // Set up ACSS using Stripe
      var stripe = Stripe(controller.stripeKeyTarget.value, { stripeAccount: controller.stripeAccountTarget.value });
      stripe.confirmAcssDebitSetup(clientSecret, {
        payment_method: {
          billing_details: {
            name: controller.accountHolderTarget.value,
            email: controller.email,
          },
        },
      }).then(function(result) {
        if (result.error) {
          acssButton.removeClass("is-loading");
          console.log(result.error.message);
        } else {
          acssButton.removeClass("is-loading is-primary");
          acssButton.addClass("is-success");
          acssButton.prop("disabled", true);
          acssButton.find("span").removeClass("is-hidden");
          // Handle next step based on SetupIntent"s status.
          controller.paymentMethodField.val(result.setupIntent.payment_method);
          controller.submissionField.click();
        }
      });
    });
  }

  acssIntervalDescription(frequency, start_at_month, start_at_year, trial) {
    if (frequency == "once") {
      return "only once, within the next 30 days";
    } else if (trial) {
      var today = new Date();
      var month = today.toLocaleString("default", { month: "short" });
      var year = today.getFullYear();
      return `on the 15th of every month, starting ${month} ${year}`;
    } else if (frequency == "monthly") {
      return `on the 15th of every month, starting ${start_at_month} ${start_at_year}`;
    } else if (frequency == "quarterly") {
      return `every three months, starting ${start_at_month} ${start_at_year}`;
    } else if (frequency == "yearly") {
      return `once a year, starting ${start_at_month} ${start_at_year}`;
    } else {
      return "on the 15th of every month";
    }
  }

  get paymentMethodField() { return $(`#${this.paymentMethodFieldTarget.value}`) }
  get submissionField() { return document.getElementById(`${this.submissionFieldTarget.value}`) }
  get frequency() { return $("#campaign_contribution_frequency").val() || this.frequencyTarget.value }
  get startMonth() { return $("#campaign_contribution_start_at_month").val() || this.startMonthTarget.value }
  get startYear() { return $("#campaign_contribution_start_at_year").val() || this.startYearTarget.value }
  get trial() {
    if ($("#campaign_contribution_trial_amount_dollars").length) {
      return !!$("#campaign_contribution_trial_amount_dollars").val();
    } else {
      return !!this.trialTarget.value;
    }
  }
  get email() { return $("#campaign_contribution_email").val() || this.emailTarget.value }
  get firstName() { return $("#campaign_contribution_first_name").val() }
  get lastName() { return $("#campaign_contribution_last_name").val() }
  get partnerId() { return this.partnerIdTarget.value }
  get paymentDetails() {
    return {
      email: this.email,
      frequency: this.frequency,
      start_at_month: this.startMonth,
      start_at_year: this.startYear,
      trial: this.trial,
      partner_id: this.partnerId
    }
  }
}
