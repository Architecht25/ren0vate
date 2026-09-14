import { Controller } from "@hotwired/stimulus"

// Remplace un ancien <script> inline (DOMContentLoaded/turbo:load) qui ne se
// réexécutait pas de façon fiable lors des navigations Turbo Drive — voir
// commit f709cf6 pour la tentative précédente. Un contrôleur Stimulus se
// (re)connecte systématiquement à chaque visite, sans dépendre de la
// réexécution d'un <script> inline par Turbo.
export default class extends Controller {
  static targets = [
    "card",
    "form",
    "titreHidden",
    "regionHidden",
    "propertyIdHidden",
    "projectIdHidden",
    "titrePanel",
    "titreVisible",
    "launchButton",
  ]

  select(event) {
    const card = event.currentTarget

    // Désélectionner les autres cartes
    this.cardTargets.forEach((c) => {
      c.classList.remove("chantier-selected")
      c.querySelector(".selected-indicator")?.classList.add("d-none")
    })

    // Sélectionner celle-ci
    card.classList.add("chantier-selected")
    card.querySelector(".selected-indicator")?.classList.remove("d-none")

    const region = card.dataset.region || ""
    const regionLabel = region ? region.charAt(0).toUpperCase() + region.slice(1) : ""
    const mois = new Date().toLocaleDateString("fr-BE", { month: "short", year: "numeric" })
    const titreGenere = `${card.dataset.nom} · ${regionLabel} · ${mois}`

    this.projectIdHiddenTarget.value = card.dataset.projectId
    this.propertyIdHiddenTarget.value = card.dataset.propertyId
    this.regionHiddenTarget.value = region
    this.titreHiddenTarget.value = titreGenere

    this.titrePanelTarget.classList.remove("d-none")
    this.titreVisibleTarget.value = titreGenere

    this.launchButtonTarget.disabled = false
  }

  syncTitre() {
    this.titreHiddenTarget.value = this.titreVisibleTarget.value || "Sans titre"
  }

  launch() {
    this.formTarget.submit()
  }
}
