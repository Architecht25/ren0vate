import { Controller } from "@hotwired/stimulus"

// ✅ Contrôleur de calcul des primes, version Rails
export default class extends Controller {
  static targets = ["result"]

  connect() {
    console.log("📊 PrimeCalculController connecté");
    this.categorie = 3; // Pour le moment, on fixe la catégorie à 3 (sera dynamique plus tard)
    this.plafondsParCategorie = { "4": 5750, "3": 4025 };
    this.groupesPlafond = {
      toiture: ["isolation_toiture", "renovation_toiture"],
      murs: ["isolation_murs_cat34", "renovation_murs"],
      sol: ["isolation_sol", "renovation_sol"]
    };
  }

  calculer(event) {
    const input = event.currentTarget;
    const slug = input.dataset.slug;
    const span = input.closest(".input-group").querySelector(".prime-result");

    if (!slug || !span) return;

    const valeur = parseFloat(input.value || 0);
    const prime = window.primes.find(p => p.slug === slug);
    if (!prime || !prime.valeursParCategorie?.[this.categorie]) return;

    const regle = prime.valeursParCategorie[this.categorie];
    let montant = 0;

    switch (regle.type) {
      case "pourcentage_et_plafond":
        montant = Math.min(valeur * (regle.pourcentage / 100), regle.plafond);
        break;

      case "montant_m2_et_limite":
        montant = Math.min(valeur * regle.montant_m2, regle.surface_max * regle.montant_m2);
        break;

      case "forfait_et_plafond_facture":
        montant = regle.forfaits?.[valeur] || regle.forfait || 0;
        if (regle.plafond_pourcentage && !isNaN(valeur)) {
          montant = Math.min(montant, valeur * (regle.plafond_pourcentage / 100));
        }
        break;

      default:
        montant = 0;
    }

    const { montant: montantPlafonne, resteDisponible } = this.appliquerPlafondGroupe(slug, montant);
    span.textContent = `${montantPlafonne.toFixed(2)} €`;
    span.title = montantPlafonne === resteDisponible ? "Plafond global atteint pour ce groupe (ex. toiture)" : "";
  }

  appliquerPlafondGroupe(slug, montantPropose) {
    const groupeTrouve = Object.entries(this.groupesPlafond).find(([_, slugs]) => slugs.includes(slug));
    if (!groupeTrouve) return { montant: montantPropose, resteDisponible: Infinity };

    const slugsDuGroupe = groupeTrouve[1];
    const plafond = this.plafondsParCategorie[this.categorie];
    if (!plafond) return { montant: montantPropose, resteDisponible: Infinity };

    const montantGroupe = slugsDuGroupe.reduce((somme, s) => {
      const span = document.querySelector(`.prime-result[data-slug="${s}"]`);
      if (!span) return somme;
      const montantCarte = parseFloat(span.textContent.replace("€", "").replace(",", ".") || 0);
      return somme + montantCarte;
    }, 0);

    const spanCourant = document.querySelector(`.prime-result[data-slug="${slug}"]`);
    const montantActuel = parseFloat(spanCourant?.textContent.replace("€", "").replace(",", ".") || 0);
    const resteDisponible = plafond - (montantGroupe - montantActuel);
    const montantFinal = Math.min(montantPropose, resteDisponible);

    return { montant: montantFinal, resteDisponible };
  }
}
