import { Controller } from "stimulus"
import { debounce } from "underscore"

export default class extends Controller {
  static targets = [ "query", "results" ]

  initialize() {
    this.search = debounce(this.search, 100)
  }

  search(event) {
    const resultsTarget = this.resultsTarget;
    $.ajax({
      type: 'GET',
      dataType: 'html',
      url: this.queryTarget.dataset.autocompleteUrl,
      data: {
        'name': this.queryTarget.value,
        'from': this.queryTarget.dataset.autocompleteFrom
      },
      success: function(response) {
        resultsTarget.innerHTML = response;
      }
    })
  }
}
