import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["surfaceToiture", "surfaceMurs", "result"]

  connect() {
    this.calculateAndUpdate()
  }

  // Gestion du changement de surface toiture
  surfaceToitureChanged() {
    this.calculateAndUpdate()
    this.triggerAutoSave()
  }

  // Gestion du changement de surface murs
  surfaceMursChanged() {
    this.calculateAndUpdate()
    this.triggerAutoSave()
  }

  // Calcul et mise à jour de l'affichage
  calculateAndUpdate() {
    const surfaceToiture = parseFloat(this.surfaceToitureTarget.value) || 0
    const surfaceMurs = parseFloat(this.surfaceMursTarget.value) || 0


    let montantTotal = 0

    // Logique de calcul amiante Flandre
    // - 8€/m² pour la toiture
    // - 4€/m² pour les murs si pas de toiture
    // - 12€/m² pour les murs si toiture incluse

    if (surfaceToiture > 0) {
      montantTotal += surfaceToiture * 8 // 8€/m² toiture

      if (surfaceMurs > 0) {
        montantTotal += surfaceMurs * 12 // 12€/m² murs si toiture incluse
      }
    } else if (surfaceMurs > 0) {
      montantTotal += surfaceMurs * 4 // 4€/m² murs uniquement
    }


    // Formatage et affichage du résultat
    const montantFormate = montantTotal.toFixed(2) + " €"
    this.resultTarget.textContent = montantFormate

    // Animation du résultat si montant > 0
    if (montantTotal > 0) {
      this.resultTarget.classList.add('text-success')
      this.resultTarget.classList.remove('text-muted')
    } else {
      this.resultTarget.classList.remove('text-success')
      this.resultTarget.classList.add('text-muted')
    }


    // Mettre à jour le total global des primes via le système existant
    this.updateGlobalTotal()
  }

  // Mettre à jour le total global
  updateGlobalTotal() {
    const flandreController = document.querySelector('[data-controller="flandre-simulation"]')
    if (flandreController && window.Stimulus) {
      const controller = window.Stimulus.getControllerForElementAndIdentifier(flandreController, 'flandre-simulation')
      if (controller && controller.updateTotalGlobal) {
        controller.updateTotalGlobal()
      }
    }
  }

  // Déclencher la sauvegarde automatique
  triggerAutoSave() {
    const flandreController = document.querySelector('[data-controller="flandre-simulation"]')

    if (flandreController && window.Stimulus) {
      const controller = window.Stimulus.getControllerForElementAndIdentifier(flandreController, 'flandre-simulation')

      if (controller && typeof controller.triggerSave === 'function') {

        // Délai pour permettre à l'affichage de se mettre à jour
        setTimeout(() => {
          controller.triggerSave()
        }, 500)
      }
    }
  }

  // Restaurer les données amiante depuis la sauvegarde
  restoreData(amianteData) {

    try {
      // Restaurer la surface toiture
      if (amianteData.surface_toiture !== undefined) {
        this.surfaceToitureTarget.value = amianteData.surface_toiture
      }

      // Restaurer la surface murs
      if (amianteData.surface_murs !== undefined) {
        this.surfaceMursTarget.value = amianteData.surface_murs
      }

      // Recalculer et mettre à jour l'affichage après restauration
      setTimeout(() => {
        this.calculateAndUpdate()
      }, 100)

    } catch (error) {
    }
  }
}
