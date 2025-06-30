import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  select(event) {
    const userType = event.currentTarget.dataset.user
    localStorage.setItem("userType", userType)

    const testSection = document.getElementById("eligibility-test")
    if (testSection) testSection.classList.remove("d-none")
  }
}
