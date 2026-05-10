import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "cookie-consent-accepted"

export default class extends Controller {
  connect() {
    if (localStorage.getItem(STORAGE_KEY)) {
      this.element.remove()
    }
  }

  accept() {
    localStorage.setItem(STORAGE_KEY, "1")
    this.element.remove()
  }
}
