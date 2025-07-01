import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("✅ Controller region-selector bien connecté")
  }

  select(event) {
    const selectedRegion = event.target.dataset.region
    console.log("➡️ Région sélectionnée :", selectedRegion)
    localStorage.setItem("region", region);

    // On récupère tous les blocs ciblés par le controller region-display
    const regionDisplay = document.querySelector('[data-controller="region-display"]')

    if (!regionDisplay) {
      console.warn("❌ Aucun data-controller='region-display' trouvé.")
      return
    }

    const allTargets = regionDisplay.querySelectorAll('[data-region-display-target]')

    // On cache tous les blocs
    allTargets.forEach(el => el.classList.add("d-none"))

    // Puis on affiche celui correspondant à la région sélectionnée
    const targetToShow = regionDisplay.querySelector(`[data-region-display-target="${selectedRegion}"]`)

    if (targetToShow) {
      targetToShow.classList.remove("d-none")
    } else {
      console.warn(`⚠️ Aucune cible trouvée pour la région : ${selectedRegion}`)
    }
  }
}
