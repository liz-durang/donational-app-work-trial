import { Controller } from "stimulus"

export default class extends Controller {
  allowKeypressWhenInteger(event) {
    event.returnValue = (String(event.key).match(/\d/) !== null)
  }
}
