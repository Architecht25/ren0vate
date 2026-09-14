// Ce fichier gère le calcul estimatif de la catégorie de prime sur la home page pour identifier rapidement si l'utilisateur est en catégorie 1, 2, 3 ou 4.
// Il s'agit d'une estimation et non d'un calcul précis. C'est volontaire pour inviter l'utilisateur à se diriger vers le login.

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["resultAffinage"]

  connect() {
  }

// ========== MÉTHODES FLANDRE ==========

  estimerCategorie() {
    const statut = document.getElementById("statut-familial").value
    const nbCharges = parseInt(document.getElementById("personnes-charge").value)
    const revenuInput = document.getElementById("revenu-net").value

    if (!statut || isNaN(nbCharges) || !revenuInput) {
      alert("Veuillez remplir tous les champs pour estimer votre catégorie.")
      return
    }

    // Stocker dans localStorage
    localStorage.setItem("statut_familial", statut)
    localStorage.setItem("personnes_charge", nbCharges)
    localStorage.setItem("revenu_net", revenuInput)

    // Convertir la valeur sélectionnée en revenu numérique basé sur les seuils de catégories
    let revenuAnnuel = 0
    switch (revenuInput) {
      case "-24320":
        revenuAnnuel = 20000 // Catégorie 4 pour la plupart des situations
        break
      case "24231-42340":
        revenuAnnuel = 35000 // Catégorie 4 pour couple, 3 pour seul
        break
      case "42341-53880":
        revenuAnnuel = 48000 // Catégorie 3 pour la plupart des situations
        break
      case "53881+":
        // Pour >53.881€, adapter selon la situation familiale
        // Couple avec enfant(s) : probablement catégorie 2
        // Seul ou couple sans enfant : probablement catégorie 1
        if ((statut === "couple-enfant" && nbCharges > 0) || (statut === "isolé-enfant" && nbCharges > 0)) {
          revenuAnnuel = 70000 // Valeur qui donne généralement catégorie 2 avec enfants
        } else {
          revenuAnnuel = 90000 // Valeur qui donne catégorie 1 sans enfants
        }
        break
    }

    // Calculer la catégorie selon les vraies règles Flandre
    let categorieEstimee = this.calculerCategorieFlandre(revenuAnnuel, statut, nbCharges)

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
    }
  }

  // Méthode appelée par data-action sur #go-simulateur
  goToSimulateur() {
    const cat = localStorage.getItem("categorie");
    const catEstimee = localStorage.getItem("categorieEstimee");

    // Mode wizard (page flandre pré-login) : naviguer vers étape 4 sans rechargement
    const wizardEl = document.getElementById("flandre-wizard")
    if (wizardEl) {
      document.dispatchEvent(new CustomEvent("flandre:category:refined", {
        detail: { categorie: catEstimee || cat }
      }))
      return
    }

    // Mode hors-wizard : rechargement avec paramètres
    this.togglePrimesSection(true);
    window.location.href = `/flandre?categorie=${cat}&categorieEstimee=${catEstimee || ""}`;
  }

  // Méthode pour calculer la catégorie Flandre selon les vraies règles du seed
  calculerCategorieFlandre(revenuAnnuel, statut, nbCharges) {
    // Seuils basés sur les données du seed flandre/categories.rb
    // Plus le revenu est élevé, plus le numéro de catégorie est bas (1 = revenus élevés, 4 = revenus faibles)
    const categories = [
      {
        numero: "4",
        seuil_max: 24230,
        seuil_avec_charge_max: 36340,
        couple_sans_charge_max: 36340
      },
      {
        numero: "3",
        seuil_max: 42340,
        seuil_avec_charge_max: 59270,
        couple_sans_charge_max: 59270
      },
      {
        numero: "2",
        seuil_max: 53880,
        seuil_avec_charge_max: 76980,
        couple_sans_charge_max: 76980
      }
      // Catégorie 1 = au-dessus des seuils de la catégorie 2
    ]

    const increment_par_personne = 4320

    // Déterminer le seuil applicable selon la situation
    for (let cat of categories) {
      let seuilMaxApplicable = 0

      if (statut === "isolé") {
        // Isolé sans enfant
        seuilMaxApplicable = cat.seuil_max
      } else if (statut === "isolé-enfant") {
        // Isolé avec enfant(s) à charge
        seuilMaxApplicable = cat.seuil_avec_charge_max + (nbCharges > 0 ? (nbCharges - 1) * increment_par_personne : 0)
      } else if (statut === "couple") {
        // Couple sans enfant
        seuilMaxApplicable = cat.couple_sans_charge_max
      } else if (statut === "couple-enfant") {
        // Couple avec enfant(s)
        seuilMaxApplicable = cat.couple_sans_charge_max + nbCharges * increment_par_personne
      }

      // Si le revenu est inférieur ou égal au seuil MAX de cette catégorie, on est dans cette catégorie
      if (revenuAnnuel <= seuilMaxApplicable) {
        return cat.numero
      }
    }

    // Si le revenu dépasse tous les seuils, on est en catégorie 1 (revenus élevés)
    return "1"
  }

// ========== MÉTHODES BRUXELLES ==========

  estimerCategorieBruxelles() {

    const statut = document.getElementById("category_estimation_bruxelles_statut_familial")?.value
    const nbCharges = parseInt(document.getElementById("category_estimation_bruxelles_enfants_charge")?.value || "0")
    const revenu = document.getElementById("category_estimation_bruxelles_revenu_net")?.value


    if (!statut || !revenu) {
      alert("Veuillez remplir tous les champs obligatoires pour estimer votre catégorie.")
      return
    }

    // Stocker dans localStorage spécifique à Bruxelles
    localStorage.setItem("bruxelles_statut_familial", statut)
    localStorage.setItem("bruxelles_enfants_charge", nbCharges)
    localStorage.setItem("bruxelles_revenu_net", revenu)

    // Estimation pour Bruxelles basée sur les tranches de revenus (3 catégories)
    let categorieEstimee = "3"

    switch (revenu) {
      case "faible":
        categorieEstimee = "3"
        break
      case "moyen":
        categorieEstimee = "2"
        break
      case "eleve":
        categorieEstimee = "1"
        break
    }

    // Affichage dans le bloc resultAffinage
    const badge = `<span class="badge rounded-pill bg-primary">Catégorie ${categorieEstimee}</span>`
    localStorage.setItem("bruxelles_categorie_badge", badge);

    this.resultAffinageTarget.innerHTML = `
      <p class="mt-2">
        ✅ Sur base de vos réponses, vous êtes probablement en ${badge} pour les primes RENOLUTION Bruxelles.
      </p>
      <p class="text-muted small">
        Cette estimation vous donne une idée de vos primes. Pour un calcul précis, consultez votre espace personnel.
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
    }

    localStorage.setItem("bruxelles_categorie_estimee", categorieEstimee)
    localStorage.setItem("bruxellesCategorieEstimee", categorieEstimee);


    // Déclencher un événement pour que les contrôleurs Bruxelles se mettent à jour
    document.dispatchEvent(new CustomEvent('bruxelles:category:changed', {
      detail: { categorie: `bruxelles_cat${categorieEstimee}` }
    }));
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

  // ========== MÉTHODES WALLONIE ==========

  estimerCategorieWallonie(event) {
    // Empêcher la soumission du formulaire
    event.preventDefault()

    const statut = document.getElementById("category_estimation_wallonie_statut_familial")?.value
    const enfantsCharge = parseInt(document.getElementById("category_estimation_wallonie_enfants_charge")?.value || "0")
    const personnesAgeesCharge = parseInt(document.getElementById("category_estimation_wallonie_personnes_agees_charge")?.value || "0")
    const revenuTranche = document.getElementById("category_estimation_wallonie_revenu_net")?.value

    if (!statut || !revenuTranche) {
      alert("Veuillez remplir tous les champs obligatoires pour estimer votre catégorie.")
      return
    }

    // Stocker dans localStorage pour Wallonie
    localStorage.setItem("wallonie_statut_familial", statut)
    localStorage.setItem("wallonie_enfants_charge", enfantsCharge)
    localStorage.setItem("wallonie_personnes_agees_charge", personnesAgeesCharge)
    localStorage.setItem("wallonie_revenu_tranche", revenuTranche)

    // Détermination de la catégorie basée sur le revenu
    let categorieWallonie = "R3" // Par défaut - catégorie moyenne

    switch (revenuTranche) {
      case "r1":
        categorieWallonie = "R1"
        break
      case "r2":
        categorieWallonie = "R2"
        break
      case "r3":
        categorieWallonie = "R3"
        break
      case "r4":
        categorieWallonie = "R4"
        break
      case "r5":
        categorieWallonie = "R5"
        break
    }


    // Affichage du résultat
    const badge = `<span class="badge rounded-pill bg-success">Catégorie ${categorieWallonie}</span>`
    localStorage.setItem("wallonie_categorie_badge", badge)
    localStorage.setItem("wallonie_categorie", categorieWallonie)

    if (this.hasResultAffinageTarget) {
      this.resultAffinageTarget.innerHTML = `
        <div class="alert alert-success">
          <h6 class="alert-heading">
            <i class="bi bi-check-circle me-2"></i>
            Catégorie déterminée
          </h6>
          <p class="mb-2">
            ✅ Selon vos revenus, vous êtes en ${badge} pour les primes Wallonie.
          </p>
          <p class="text-muted small mb-0">
            Cette catégorie détermine vos montants de primes éligibles.
          </p>
        </div>
      `
      this.resultAffinageTarget.style.display = "block"
    }

    // Déclencher l'affichage des primes correspondantes
    this.afficherPrimesWallonie(categorieWallonie)
  }

  afficherPrimesWallonie(categorie) {

    // Convertir R1 -> wallonie_r1 pour le calculateur
    const categorieCalculateur = `wallonie_${categorie.toLowerCase()}`

    // Stocker la catégorie au bon format dans localStorage
    localStorage.setItem('selectedWallonieCategory', categorieCalculateur)

    // Masquer le placeholder et afficher les cartes
    this.togglePrimesSection(true)

    // Mettre à jour le titre de la section primes
    this.updatePrimesSectionTitleWallonie(categorie)

    // Déclencher la mise à jour des cartes avec la catégorie Wallonie
    this.updatePrimesCardsWallonie(categorieCalculateur)

    // Afficher un bouton pour voir toutes les primes
    this.addViewPrimesButtonWallonie(categorie)

    // Notifier le wizard Wallonie que la catégorie est déterminée → passer aux primes
    document.dispatchEvent(new CustomEvent("wallonie:category:refined", {
      detail: { categorie: categorieCalculateur }
    }))
  }

  updatePrimesSectionTitleWallonie(categorie) {
    const titleElement = document.querySelector('.primes-section h4')
    if (titleElement) {
      titleElement.textContent = `Vos primes éligibles Wallonie - Catégorie ${categorie}`
    }
  }

  updatePrimesCardsWallonie(categorieCalculateur) {
    // Trouver toutes les cartes de primes Wallonie
    const allPrimeCards = document.querySelectorAll('[data-controller*="prime-card"]')

    allPrimeCards.forEach(card => {
      const slug = card.dataset.slug
      const prime = window.primes?.find(p => p.slug === slug)

      if (prime) {
        // Vérifier si cette prime est éligible pour cette catégorie wallonie_r1-r5
        const isEligible = prime.eligible_categories?.includes(categorieCalculateur)

        if (isEligible) {
          card.style.display = ''
          card.classList.remove('d-none')
        } else {
          card.style.display = 'none'
          card.classList.add('d-none')
        }
      }
    })

    // Déclencher un événement pour que les contrôleurs prime-card se mettent à jour
    document.dispatchEvent(new CustomEvent('wallonie:category:changed', {
      detail: { categorie: categorieCalculateur }
    }))
  }

  addViewPrimesButtonWallonie(categorie) {
    const button = document.getElementById("go-simulateur-wallonie")
    if (button) {
      button.style.display = "inline-block"
      button.className = "btn btn-success btn-lg mt-3"
      button.innerHTML = `🎯 Voir mes primes Wallonie (${categorie})`

      // Supprimer ancien event listener s'il existe
      button.replaceWith(button.cloneNode(true))
      const newButton = document.getElementById("go-simulateur-wallonie")

      newButton.addEventListener("click", () => {
        // Scroll vers les primes
        const primesSection = document.querySelector('.primes-section')
        if (primesSection) {
          primesSection.scrollIntoView({ behavior: 'smooth' })
        }

        // Masquer le placeholder et afficher les cartes
        this.togglePrimesSection(true)
      })
    }
  }
}
