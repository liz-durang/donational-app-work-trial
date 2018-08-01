import { Controller } from "stimulus"
import { throttle } from "underscore"

export default class extends Controller {
  static targets = [ "text" ]

  initialize() {
    this.pressKey = throttle(this.pressKey, 100, { leading: false, trailing: false });
  }

  pressKey(event) {
    if (event.keyCode == 13) {
      event.preventDefault();
    } else {
      $.ajax({
        type: 'GET',
        dataType: 'html',
        url: event.currentTarget.dataset.autocompleteUrl,
        data: {
          'name': this.textTarget.value + event.key,
          'from': event.currentTarget.dataset.autocompleteFrom
        },
        success: function(data) {
          $('#results').html(data);
        }
      })
    }
  }
}
