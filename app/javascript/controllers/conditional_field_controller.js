import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ 'dependent', 'independent', 'hideable' ]
  static values = {
    trigger: String
  }

  initialize() {
    this.update(); // The form might load with the user's input already populated.
    // TODO find out why this doesn't work for gift aid field when clicking back from the Stripe page
  }

  update() {
    let conditionIsTriggered;

    if (this.independentTarget.type === "checkbox") {
      conditionIsTriggered = this.independentTarget.checked
    } else {
      conditionIsTriggered = this.conditionsMet()
    }

    if (conditionIsTriggered) {
      this.showHideableArea()
    } else {
      this.clearDependentFields()
      this.hideHideableArea()
    }
  }

  conditionsMet() {
    return this.independentTarget.value === this.triggerValue || ((this.independentTarget.value) && this.triggerValue === 'any')
  }

  showHideableArea() {
    this.hideableTarget.classList.remove("is-hidden");
  }

  hideHideableArea() {
    this.hideableTarget.classList.add("is-hidden")
  }

  clearDependentFields() {
    this.dependentTargets.forEach((el) => {el.value = ""})
  }
}

// Example usage:

// .fieldset data-controller="conditional-field"
//   .field
//     .control
//       = f.check_box :start_pledge_in_future, data: { 'conditional-field-target': 'independent', 'action': 'conditional-field#update' }
//   .fieldset data-conditional-field-target='hideable'
//     .field
//       .control
//         .select.is-fullwidth
//           = f.select :start_at_month, {}, {}, data: { 'conditional-field-target': 'dependent' } do
//             - @view_model.months.each do |month|
//               option = month
//       span.help.display-when-errors Please select a date in the future
//     .column.is-half
//       .field
//         .control
//           .select.is-fullwidth
//             = f.select :start_at_month, {}, {}, data: { 'conditional-field-target': 'dependent' } do
//               - @view_model.years.each do |year|
//                 option = year
