import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.style.backgroundColor = 'yellow';
    this.element.innerHTML = 'Simple controller fonctionne !';
  }
}
