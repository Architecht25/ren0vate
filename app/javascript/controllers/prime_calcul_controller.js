import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("📊 PrimeCalculController connecté");

    this.primes = window.primes || [];
    this.categorie = window.categorieId || "3";
    this.plafondsParCategorie = window.plafondsParCategorie || {};
    this.groupesPlafond = window.groupesPlafond || {};

    this.element.addEventListener("prime:input", this.calculer.bind(this));
    console.log("👂 Écouteur prime:input activé");
  }


  calculer(event) {
    const { slug, valeur, type } = event.detail;
    console.log("💡 Type sélectionné :", type);
    const prime = this.primes.find(p => p.slug === slug);
    if (!prime) return console.warn(`❌ Prime inconnue : ${slug}`);

    const categorieData = prime.valeurs_par_categorie?.[this.categorie];
    if (!categorieData) return console.warn(`❌ Catégorie ${this.categorie} non éligible pour ${slug}`);

    const val = parseFloat(valeur || 0);
    let montant = 0;

    switch (categorieData.type) {
      case "pourcentage_et_plafond":
        montant = Math.min((val * (categorieData.pourcentage || 0)) / 100, categorieData.plafond || Infinity);
        break;

      case "montant_m2_et_limite":
        const surfaceMax = categorieData.surface_max || Infinity;
        const surface = Math.min(val, surfaceMax);
        const base = surface * (categorieData.montant_m2 || 0);
        montant = base * (categorieData.plafond_pourcentage || 100) / 100;
        break;

      case "montant_variable_m2_et_limite":
        // Par défaut : type "exterieur" tant qu’on n’a pas de select
        const typeMur = "exterieur";
        const montantM2 = categorieData.montants_m2?.[typeMur] || 0;
        const surfVar = Math.min(val, categorieData.surface_max || Infinity);
        montant = surfVar * montantM2;
        montant = montant * (categorieData.plafond_pourcentage || 100) / 100;
        break;

      case "forfait_et_plafond_facture":
        const typePompe = type || "air_eau"; // fallback
        const forfait = categorieData.forfaits?.[typePompe] || 0;
        montant = forfait;
        break;

      case "forfait":
      case "montant":
        montant = categorieData.forfait || categorieData.valeur || 0;
        break;

      case "prime_conditionnelle":
        montant = 0;
        break;

      default:
        console.warn(`❌ Type de prime non pris en charge : ${categorieData.type}`);
    }

    const plafonné = this.appliquerPlafondGroupe(slug, montant);
    this.mettreAJourMontant(slug, plafonné.montant);
  }

  appliquerPlafondGroupe(slug, montantPropose) {
    const groupe = Object.entries(this.groupesPlafond || {}).find(([_, slugs]) => Array.isArray(slugs) && slugs.includes(slug));
    if (!groupe) return { montant: montantPropose, resteDisponible: Infinity };

    const slugs = groupe[1];
    const plafond = this.plafondsParCategorie[this.categorie] || Infinity;

    const totalGroupe = slugs.reduce((somme, s) => {
      const span = document.querySelector(`.prime-result[data-slug="${s}"]`);
      const val = parseFloat(span?.textContent.replace("€", "").replace(",", ".") || 0);
      return somme + (isNaN(val) ? 0 : val);
    }, 0);

    const resteDisponible = plafond - totalGroupe;
    const montantFinal = Math.min(montantPropose, resteDisponible);

    return { montant: montantFinal, resteDisponible };
  }

  mettreAJourMontant(slug, montant) {
    const carte = document.querySelector(`[data-slug="${slug}"]`);
    const span = carte?.querySelector(".prime-result");

    if (span) {
      span.textContent = `${montant.toFixed(2)} €`;
    }

    const totalSpan = document.querySelector("#total-primes-affiche");
    if (totalSpan) {
      const total = Array.from(document.querySelectorAll(".prime-result"))
        .reduce((sum, el) => sum + parseFloat(el.textContent.replace("€", "").replace(",", ".") || 0), 0);
      totalSpan.textContent = `${total.toFixed(2)} €`;
    }
  }
}
