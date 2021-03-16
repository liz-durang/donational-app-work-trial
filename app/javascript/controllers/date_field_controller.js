import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "panel", "label" ]

  hideOrShowPanel(event) {
    event.preventDefault();

    var today = new Date();
    var day = today.getDate();
    var month = document.getElementsByName("campaign_contribution[start_at_month]")[0].value
    var year = document.getElementsByName("campaign_contribution[start_at_year]")[0].value

    var monthsHash = {
      'Jan': '01',
      'Feb': '02',
      'Mar': '03',
      'Apr': '04',
      'May': '05',
      'Jun': '06',
      'Jul': '07',
      'Aug': '08',
      'Sep': '09',
      'Oct': '10',
      'Nov': '11',
      'Dec': '12'
    }

    // Create subscription date. Date constructor receives month index, that's why we pass month - 1.
    var subscriptionDate = new Date(year, monthsHash[month] - 1 , day);

    // Calculate months difference between subscription date and today.
    var months = subscriptionDate.getMonth() - today.getMonth() + (12 * (subscriptionDate.getFullYear() - today.getFullYear()))

    if (months > 1) {
      this.panelTarget.classList.remove('is-hidden');
    } else {
      this.panelTarget.classList.add('is-hidden');
    }

    var allYears= subscriptionDate.getFullYear() - today.getFullYear();
    var partialMonths = subscriptionDate.getMonth() - today.getMonth();
    if (partialMonths < 0) {
      allYears--;
      partialMonths = partialMonths + 12;
    }

    var label = 'Your pledge starts in '
    if (allYears > 0) {
      label += ` ${this.maybePluralize(allYears, 'year')}`
      if (partialMonths > 0) {
        label += ` ${this.maybePluralize(partialMonths, 'month')}.`
      } else {
        label += '.'
      }
    } else {
      label += ` ${this.maybePluralize(months, 'month')}.`
    }

    this.labelTarget.innerText = label;
  }

  private

  maybePluralize(count, noun, suffix = 's') {
    return `${count} ${noun}${count !== 1 ? suffix : ''}`;
  }
}
