import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["flandre", "bruxelles", "wallonie"]

  connect() {
    console.log("✅ Controller region-display bien connecté")
    window.addEventListener("region:changed", () => this.update());
    this.update(); // au chargement
  }

  update() {
    const region = localStorage.getItem("region");

    this.flandreTarget.classList.add("d-none");
    this.bruxellesTarget.classList.add("d-none");
    this.wallonieTarget.classList.add("d-none");

    if (region === "flandre" && this.hasFlandreTarget) {
      this.flandreTarget.classList.remove("d-none");
    }
    if (region === "bruxelles" && this.hasBruxellesTarget) {
      this.bruxellesTarget.classList.remove("d-none");
    }
    if (region === "wallonie" && this.hasWallonieTarget) {
      this.wallonieTarget.classList.remove("d-none");
    }
  }
}
