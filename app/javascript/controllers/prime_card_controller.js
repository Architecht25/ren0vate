import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "select"]

  connect() {
    console.log("🧮 PrimeCardController connecté pour", this.element.dataset.slug);

    // ⏳ Attend que la catégorie globale soit disponible
    setTimeout(() => {
      this.update();
    }, 100);
  }

  update(event) {
    const slug = this.element.dataset.slug;
    const valeur = this.hasInputTarget ? this.inputTarget.value : 0;
    const type = this.hasSelectTarget ? this.selectTarget.value : null;
    const categorie = window.categorieId || "3";

    console.log("🎯 Placeholder mis à jour avec catégorie :", categorie);

    // Placeholder dynamique
    if (this.hasInputTarget) {
      this.inputTarget.placeholder = ["4", "3"].includes(categorie)
        ? "Montant total de la facture (€)"
        : "Surface en m²";
    }

    // Événement pour déclencher le calcul
    this.element.dispatchEvent(new CustomEvent("prime:input", {
      bubbles: true,
      detail: { slug, valeur, type }
    }));
  }
}
