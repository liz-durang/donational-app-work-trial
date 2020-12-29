import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "tab", "panel" ]

  initialize() {
    this.showTab()
  }

  change(event) {
    this.index = this.tabTargets.indexOf(event.currentTarget)
  }

  showTab() {      
    this.tabTargets.forEach((tab, index) => {
      const panel = this.panelTargets[index]
      tab.classList.toggle("is-active", index == this.index)
      panel.classList.toggle("is-hidden", index != this.index)
    })
  }

  get index() {
    return parseInt(this.data.get("index") || 0)
  }

  set index(value) {
    this.data.set("index", value)
    this.showTab()
  }
}