import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "renolutionButton"]

  connect() {
    console.log("🔄 Contrôleur Eligibility Retester connecté")
  }

  async retestEligibility(event) {
    const button = event.currentTarget
    const simulationId = button.dataset.simulationId

    if (!simulationId) {
      console.error("❌ ID de simulation manquant")
      return
    }

    console.log(`🔄 Relance du test d'éligibilité investissements pour simulation ${simulationId}`)

    await this.performEligibilityTest(button, simulationId, 'check_eligibility_investment', 'investissements')
  }

  async retestRenolutionEligibility(event) {
    const button = event.currentTarget
    const simulationId = button.dataset.simulationId

    if (!simulationId) {
      console.error("❌ ID de simulation manquant")
      return
    }

    console.log(`🔄 Relance du test d'éligibilité RENOLUTION pour simulation ${simulationId}`)

    await this.performEligibilityTest(button, simulationId, 'check_eligibility_renolution', 'RENOLUTION')
  }

  async performEligibilityTest(button, simulationId, endpoint, testType) {
    // Désactiver le bouton et changer le texte
    const originalText = button.innerHTML
    button.disabled = true
    button.innerHTML = '<i class="spinner-border spinner-border-sm me-2"></i>Test en cours...'

    try {
      const response = await fetch(`/simulations/${simulationId}/${endpoint}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })

      if (response.ok) {
        const result = await response.json()
        console.log(`✅ Test d'éligibilité ${testType} terminé:`, result)

        // Recharger la page pour afficher les nouveaux résultats
        window.location.reload()
      } else {
        throw new Error(`Erreur HTTP: ${response.status}`)
      }
    } catch (error) {
      console.error(`❌ Erreur lors du test d'éligibilité ${testType}:`, error)

      // Afficher une notification d'erreur
      this.showError(`Erreur lors du test d'éligibilité ${testType}. Veuillez réessayer.`)

      // Réactiver le bouton
      button.disabled = false
      button.innerHTML = originalText
    }
  }

  showError(message) {
    // Créer une notification d'erreur temporaire
    const notification = document.createElement('div')
    notification.className = 'alert alert-danger alert-dismissible fade show position-fixed'
    notification.style.top = '20px'
    notification.style.right = '20px'
    notification.style.zIndex = '9999'
    notification.innerHTML = `
      ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `
    document.body.appendChild(notification)

    // Supprimer automatiquement après 5 secondes
    setTimeout(() => {
      if (notification.parentNode) {
        notification.remove()
      }
    }, 5000)
  }
}
