import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  select(event) {
    const region = event.currentTarget.dataset.region
    localStorage.setItem("region", region)

    const section = document.querySelector('[data-user-type-target="section"]')
    if (section) section.classList.remove("d-none")
  }
}
