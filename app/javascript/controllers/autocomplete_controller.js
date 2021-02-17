import { Controller } from "stimulus";
import { debounce } from "underscore";

export default class extends Controller {
  static targets = ["query", "results"];

  initialize() {
    this.search = debounce(this.search, 100);
  }

  search(event) {
    const resultsTarget = this.resultsTarget;

    const url =
      this.queryTarget.dataset.autocompleteUrl +
      "?name=" +
      this.queryTarget.value +
      "&from=" +
      this.queryTarget.dataset.autocompleteFrom;

    fetch(url, { headers: { "Content-Type": "text/html" } })
      .then((response) => {
        return response.text();
      })
      .then((html) => (resultsTarget.innerHTML = html));
  }
}
