import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "select"]

  connect() {
    console.log("🧮 PrimeCardController connecté pour", this.element.dataset.slug);

    // On attend un court instant pour que window.categorieId soit bien défini
    setTimeout(() => {
      this.update();
    }, 100);
  }

  update(event) {
    const slug = this.element.dataset.slug;
    const valeur = this.hasInputTarget ? this.inputTarget.value : 0;
    const type = this.hasSelectTarget ? this.selectTarget.value : null;
    const categorie = window.categorieId || "3";

    // 🎯 Recherche de la prime dans window.primes
    const prime = window.primes.find(p => p.slug === slug);

    if (prime && this.hasInputTarget) {
      const placeholderTexte = prime.placeholder?.[categorie];

      // Si un placeholder spécifique existe pour cette catégorie, on l'applique
      if (placeholderTexte) {
        this.inputTarget.placeholder = placeholderTexte;
        console.log(`📌 Placeholder pour ${slug} (cat. ${categorie}) :`, placeholderTexte);
      } else {
        // Fallback générique si aucun placeholder spécifique
        this.inputTarget.placeholder = ["4", "3"].includes(categorie)
          ? "Montant total de la facture (€)"
          : "Surface en m²";
      }
    }

    // 🧮 Déclenchement du calcul de prime
    this.element.dispatchEvent(new CustomEvent("prime:input", {
      bubbles: true,
      detail: { slug, valeur, type }
    }));
  }
}
