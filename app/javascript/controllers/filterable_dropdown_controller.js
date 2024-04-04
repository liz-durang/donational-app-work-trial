
import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ['input', 'menu', 'item', 'errorMessage']

  initialize() {
    this.hideMenu()
  }

  filter() {
    const filterValue = this.inputTarget.value.toUpperCase();
    let allHidden = true;

    this.itemTargets.forEach(item => {
      const itemText = item.innerHTML.toUpperCase();
      const isMatch = (filterValue.length === 1)
                      ? itemText.startsWith(filterValue)
                      : itemText.includes(filterValue);

      if (isMatch) {
        item.style.display = "";
        allHidden = false;
      } else {
        item.style.display = "none";
      }
    });

    this.menuTarget.style.display = allHidden ? "none" : "block";
  }

  select(event) {
    event.preventDefault();
    this.inputTarget.value = event.target.innerText;
    if (this.inputTarget.value === event.target.innerText) {
      this.hideMenu();
    } else {
      window.setTimeout(this.select, 100, event);
    }
  }

  toggleMenu() {
    if (this.menuTarget.style.display === "none") {
      this.showAll();
    } else {
      this.hideMenu();
    }
  }

  hideErrorMessage() {
    this.errorMessageTarget.style.display = "none";
  }

  private

  hideMenu() {
    this.menuTarget.style.display = "none";
  }

  showAll() {
    this.menuTarget.style.display = "block";
    this.itemTargets.forEach(item => {
      item.style.display = "";
    });
  }
}
