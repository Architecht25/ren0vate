// ce fichier gère la calcul estimatif de la catégorie de prime sur la home page pour identifier rapidement si l'utilisateur es t en catégoire 1, 2, 3 ou 4.
// il s'agit d'une estimation et non d'un calcul précis. c'est volontaire pour inviter l'utilisateur à se diriger vers le login.

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["resultAffinage"]

  connect() {
    console.log('🎯 CategorieEstimation controller connecté !');
  }

  estimerCategorie() {
    console.log('🎯 EstimerCategorie déclenché !');

    const statut = document.getElementById("statut-familial").value
    const nbCharges = parseInt(document.getElementById("personnes-charge").value)
    const revenu = document.getElementById("revenu-net").value

    if (!statut || isNaN(nbCharges) || !revenu) {
      alert("Veuillez remplir tous les champs pour estimer votre catégorie.")
      return
    }

    // Stocker dans localStorage
    localStorage.setItem("statut_familial", statut)
    localStorage.setItem("personnes_charge", nbCharges)
    localStorage.setItem("revenu_net", revenu)

    // Estimation simple basée uniquement sur la tranche de revenu
    let categorieEstimee = "4"

    switch (revenu) {
      case "-24320":
        categorieEstimee = "4"
        break
      case "24231-42340":
        categorieEstimee = "3"
        break
      case "42341-53880":
        categorieEstimee = "2"
        break
      case "53881+":
        categorieEstimee = "1"
        break
    }

    // Affichage dans le bloc resultAffinage
    const badge = `<span class="badge rounded-pill bg-dark">Catégorie ${categorieEstimee}</span>`
    localStorage.setItem("categorie_badge", badge);

    this.resultAffinageTarget.innerHTML = `
      <p class="mt-2">
        ✅ Sur base de vos réponses, vous êtes probablement en ${badge}.
      </p>
      <p class="text-muted small">
        Pour confirmer cette estimation, une vérification plus précise est possible dans votre espace personnel.
      </p>
    `
    this.resultAffinageTarget.style.display = "block"
    this.resultAffinageTarget.classList.remove("alert-secondary", "alert-warning", "alert-info", "alert-primary")

    if (categorieEstimee === "1") {
      this.resultAffinageTarget.classList.add("alert-info")
    } else if (categorieEstimee === "2") {
      this.resultAffinageTarget.classList.add("alert-primary")
    } else if (categorieEstimee === "3") {
      this.resultAffinageTarget.classList.add("alert-warning")
    } else {
      this.resultAffinageTarget.classList.add("alert-secondary")
    }

    localStorage.setItem("categorie_estimee", categorieEstimee)
    localStorage.setItem("categorieEstimee", categorieEstimee);

    const button = document.getElementById("go-simulateur");
    if (button && (categorieEstimee || localStorage.getItem("categorie"))) {
      button.style.display = "inline-block";
      button.className = "btn btn-success btn-lg mt-3";
      button.innerHTML = "🎯 Voir mes primes personnalisées";

      // Supprimer ancien event listener s'il existe
      button.replaceWith(button.cloneNode(true));
      const newButton = document.getElementById("go-simulateur");

      newButton.addEventListener("click", () => {
        const cat = localStorage.getItem("categorie");
        const catEstimee = localStorage.getItem("categorieEstimee");
        console.log('Redirection après affinage:', { cat, catEstimee });

        // Masquer le placeholder et afficher les cartes
        this.togglePrimesSection(true);

        window.location.href = `/flandre?categorie=${cat}&categorieEstimee=${catEstimee || ""}`;
      });
    }
  }

  togglePrimesSection(show = true) {
    const placeholder = document.getElementById("primes-placeholder");
    const primesSection = document.querySelector(".primes-section");

    if (placeholder && primesSection) {
      if (show) {
        placeholder.style.display = "none";
        primesSection.style.display = "block";
      } else {
        placeholder.style.display = "block";
        primesSection.style.display = "none";
      }
    }
  }
}
