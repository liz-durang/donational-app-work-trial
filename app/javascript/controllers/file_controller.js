import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "filename", "preview" ]

  preview() {
    const file = event.currentTarget.files[0];

    if (file) {
      this.filenameTarget.innerHTML = file.name;

      const imageElement = this.previewTarget;
      const reader = new FileReader();
      reader.onload = function(e) { imageElement.src = e.target.result };
      reader.readAsDataURL(file);
    }
  }
}
