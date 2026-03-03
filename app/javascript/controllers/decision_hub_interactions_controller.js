// Controller Stimulus pour les interactions locales du Decision Hub
// Complémentaire au decision_hub_controller.js principal

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "preparationScore",
    "preparationProgressBar",
    "preparationStatus"
  ]

  connect() {
    console.log("Decision Hub Interactions controller connected")
    this.setupObligationCheckboxes()
  }

  // Configuration des checkboxes d'obligations
  setupObligationCheckboxes() {
    const checkboxes = document.querySelectorAll('.checklist input[type="checkbox"]')
    checkboxes.forEach(checkbox => {
      checkbox.addEventListener('change', () => {
        this.updatePreparationScore()
      })
    })
  }

  // Mettre à jour le score de préparation
  updatePreparationScore() {
    const checkboxes = document.querySelectorAll('.checklist input[type="checkbox"]')
    const checked = Array.from(checkboxes).filter(cb => cb.checked).length
    const total = checkboxes.length
    const percentage = Math.round((checked / total) * 100)

    // Mettre à jour l'affichage du score
    const scoreValue = document.querySelector('.score-value')
    const progressBar = document.querySelector('.preparation-score .progress-bar')

    if (scoreValue) scoreValue.textContent = percentage + '%'
    if (progressBar) {
      progressBar.style.width = percentage + '%'
      progressBar.className = `progress-bar ${percentage < 50 ? 'bg-danger' : percentage < 80 ? 'bg-warning' : 'bg-success'}`
    }

    // Mettre à jour le statut
    const remaining = total - checked
    const statusText = document.querySelector('.preparation-score small')
    if (statusText) {
      if (remaining === 0) {
        statusText.textContent = '🎉 Parfait ! Vous êtes prêt pour le dépôt'
        statusText.className = 'text-success'
      } else {
        statusText.textContent = `Encore ${remaining} étape${remaining > 1 ? 's' : ''} pour être prêt au dépôt`
        statusText.className = 'text-muted'
      }
    }
  }
}
