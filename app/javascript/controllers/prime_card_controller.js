import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    console.log("🧮 PrimeCardController actif pour", this.element.dataset.slug)
  }

  update(event) {
    const slug = this.element.dataset.slug
    const valeur = event.currentTarget.value

    // 💥 Émet un événement personnalisé
    this.element.dispatchEvent(new CustomEvent("prime:input", {
      bubbles: true,
      detail: { slug, valeur }
    }))
  }
}
