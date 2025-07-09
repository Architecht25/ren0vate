import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.style.backgroundColor = 'lightgreen';
    this.element.innerHTML = '✅ Stimulus fonctionne !';
  }

  click() {
    alert('Stimulus fonctionne parfaitement !');
  }
}
