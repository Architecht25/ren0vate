import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "select"]

  connect() {
    console.log("🧮 PrimeCardController connecté pour", this.element.dataset.slug);
  }

  update(event) {
    const slug = this.element.dataset.slug;
    const valeur = this.hasInputTarget ? this.inputTarget.value : 0; // pour warmtepomp = 0
    const type = this.hasSelectTarget ? this.selectTarget.value : null;

    console.log("✅ Événement envoyé :", { slug, valeur, type });
    // Vérification du slug
    if (!slug) {
      console.warn("⚠️ Le slug est manquant pour cette carte prime.");
      return;
    }

    this.element.dispatchEvent(new CustomEvent("prime:input", {
      bubbles: true,
      detail: { slug, valeur, type }
    }));
  }
}
