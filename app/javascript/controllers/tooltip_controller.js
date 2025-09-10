import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tooltip"]

  connect() {
    this.initializeTooltips()
  }

  disconnect() {
    this.disposeTooltips()
  }

  initializeTooltips() {
    // Détruire les tooltips existants d'abord pour éviter les doublons
    this.disposeTooltips()

    // Trouver tous les éléments avec data-bs-toggle="tooltip" dans le scope du contrôleur
    const tooltipTriggerList = this.element.querySelectorAll('[data-bs-toggle="tooltip"]')

    this.tooltipList = Array.from(tooltipTriggerList).map(tooltipTriggerEl => {
      return new bootstrap.Tooltip(tooltipTriggerEl, {
        trigger: 'hover',
        delay: { show: 300, hide: 100 },
        html: true,
        placement: 'auto'
      })
    })
  }

  disposeTooltips() {
    if (this.tooltipList) {
      this.tooltipList.forEach(tooltip => {
        if (tooltip && typeof tooltip.dispose === 'function') {
          tooltip.dispose()
        }
      })
      this.tooltipList = []
    }
  }

  // Méthode pour réinitialiser les tooltips (utile si le contenu change dynamiquement)
  refresh() {
    this.initializeTooltips()
  }
}
