import { Controller } from "stimulus"
export default class extends Controller {
  dragover(event) {
    event.preventDefault()
    return true
  }

  dragenter(event) {
    event.preventDefault()
  }
  dragstart(event) {
    event.dataTransfer.setData("application/drag-key", event.target.getAttribute("data-drag-item-id"))
    event.dataTransfer.effectAllowed = "move"
    this.element.classList.add('is-dragging')
  }

  dragend(event) {
    this.element.classList.remove('is-dragging')
  }

  drop(event) {
    var data = event.dataTransfer.getData("application/drag-key")
    const draggedItem = this.element.parentElement.querySelector(`[data-drag-item-id='${data}']`)
    const positionComparison = this.element.compareDocumentPosition(draggedItem)
    if ( positionComparison & 4) {
      this.element.insertAdjacentElement('beforebegin', draggedItem);
    } else if ( positionComparison & 2) {
      this.element.insertAdjacentElement('afterend', draggedItem);
    }
    this.element.closest('form').submit()
    event.preventDefault()
  }
}
