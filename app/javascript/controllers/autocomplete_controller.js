import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "text", "results" ]

  pressKey(event) {
    if (event.keyCode == 13) {
      event.preventDefault();
    } else {
      var results = this.resultsTarget;
      $.ajax({
        type: 'GET',
        dataType: 'html',
        url: event.currentTarget.dataset.autocompleteUrl,
        data: {
          'name': this.textTarget.value + event.key,
          'from': event.currentTarget.dataset.autocompleteFrom
        },
        success: function(data) {
          results.innerHTML = data;
        }
      })
    }
  }
}
