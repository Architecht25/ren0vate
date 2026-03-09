import { Controller } from "@hotwired/stimulus"
import { calculerTotalToutesCartes } from "logic/prime_total_logic";

export default class extends Controller {
  connect() {
    this.primes = window.primes || [];
    this.categorie = window.categorieId || "3";

    this.groupesPlafond = {
      toiture: ["isolation_toiture", "renovation_toiture"],
      murs: ["isolation_murs", "renovation_murs"],
      sol: ["isolation_sol", "renovation_sol"]
    };

    this.plafondsParGroupeEtCategorie = {
      toiture: { "1": 0, "2": 0, "3": 4025, "4": 5750 },
      murs:    { "1": 0, "2": 0, "3": 3500, "4": 5000 },
      sol:     { "1": 0, "2": 0, "3": 1050, "4": 1500 }
    };

    this.element.addEventListener("prime:input", this.calculer.bind(this));
  }

  calculer(event) {

    const { slug, valeur, type } = event.detail;
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
        montant = surface * (categorieData.montant_m2 || 0);
        // montant *= (categorieData.plafond_pourcentage || 100) / 100;
        break;

      case "montant_variable_m2_et_limite":
        const carteElement = document.querySelector(`.prime-card[data-slug="${slug}"]`);
        const selectElement = carteElement?.querySelector(".select-type-mur");
        const typeMur = selectElement?.value || "exterieur"; // par défaut

        const montantM2 = categorieData.montants_m2?.[typeMur] || 0;
        const surfVar = Math.min(val, categorieData.surface_max || Infinity);
        montant = surfVar * montantM2;
        break;

     case "forfait_et_plafond_facture":
      if (slug === "warmtepompboiler") {
        // Chauffe-eau thermodynamique
        const facture = val || 0;
        const forfait = categorieData.forfait || Infinity;
        const plafondPourcentage = categorieData.plafond_pourcentage || 100;
        montant = Math.min(facture * (plafondPourcentage / 100), forfait);
      } else if (slug === "warmtepomp") {
        // Pompe à chaleur
        const typePompe = type || "air_eau";
        montant = categorieData.forfaits?.[typePompe] || 0;
      } else {
        montant = categorieData.forfait || 0;
      }
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
    if (["1", "2"].includes(this.categorie)) {
      return { montant: montantPropose, resteDisponible: Infinity };
    }

    let groupe = null;

    for (const [g, slugs] of Object.entries(this.groupesPlafond)) {
      if (slugs.includes(slug)) {
        groupe = g;
        break;
      }
    }

    if (!groupe) return { montant: montantPropose, resteDisponible: Infinity };

    const plafond = this.plafondsParGroupeEtCategorie[groupe][this.categorie] || Infinity;
    const slugsGroupe = this.groupesPlafond[groupe];

    const totalDejaAffiche = slugsGroupe.reduce((somme, s) => {
      if (s === slug) return somme; // on ignore la carte en cours
      const span = document.querySelector(`.prime-result[data-slug="${s}"]`);
      const val = parseFloat(span?.textContent.replace("€", "").replace(",", ".") || 0);
      return somme + (isNaN(val) ? 0 : val);
    }, 0);

    const plafondRestant = plafond - totalDejaAffiche;
    const montantFinal = Math.min(montantPropose, plafondRestant);

    return { montant: montantFinal, resteDisponible: plafondRestant };
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

    // 🔁 Mise à jour du localStorage
    calculerTotalToutesCartes();
  }

}
