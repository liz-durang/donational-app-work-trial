import { Controller } from "stimulus"

export default class extends Controller {
  static values = { config: String, delay: Number }

  connect() {
    this.index = 0
    this.alternatives = this.configValue.split('|')

    setInterval(() => { this.rotate() }, this.delayValue);
  }

  rotate() {
    this.index = (this.index + 1) % this.alternatives.length
    this.element.innerHTML = this.alternatives[this.index]
  }
}
