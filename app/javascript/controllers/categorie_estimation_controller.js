import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["resultAffinage"]

  connect() {
    console.log("🧠 Contrôleur estimation catégorie connecté")
    // Tu peux décider ici d’afficher le bloc ou le laisser caché au début
    // document.getElementById("affinage-categorie").style.display = "block"
  }

  estimerCategorie() {
    console.log("🧮 Lancement du calcul de la catégorie estimée")

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
  }
}
