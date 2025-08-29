import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sectionTitle", "totalGeneral"]

  connect() {
    console.log("🎯 Contrôleur Flandre Prime Calcul connecté")
    this.setupPrimesData()
    this.setupEventListeners()
    this.updateSectionTitle()
    this.setupAutoSaveRestore()
  }

  setupEventListeners() {
    // Écouter les événements de mise à jour des cartes enfants
    this.element.addEventListener('flandre:card:updated', this.cardUpdated.bind(this))

    // Écouter les changements de catégorie depuis le test d'éligibilité
    document.addEventListener('flandre:category:changed', (event) => {
      this.changeCategory(event.detail.category)
    })
  }

  setupPrimesData() {
    try {
      // Récupérer les données de primes depuis le script JSON injecté
      const primesScript = document.getElementById('flandre-primes-data')
      if (primesScript) {
        this.primesData = JSON.parse(primesScript.textContent)
        console.log("📊 Données de primes Flandre chargées:", Object.keys(this.primesData).length, "primes")
      } else {
        console.warn("⚠️ Script de données primes Flandre non trouvé")
        this.primesData = {}
      }

      // Récupérer les données de simulation
      const simulationScript = document.getElementById('simulation-category-data')
      if (simulationScript) {
        const simulationData = JSON.parse(simulationScript.textContent)
        this.currentCategory = simulationData.category || '1'
        this.simulationId = simulationData.simulationId
        console.log("🎯 Catégorie actuelle:", this.currentCategory, "Simulation ID:", this.simulationId)
      } else {
        this.currentCategory = '1'
        this.simulationId = null
      }

      // Exposer les données globalement
      window.flandreCurrentCategory = this.currentCategory
      window.flandrePrimesData = this.primesData
    } catch (error) {
      console.error("❌ Erreur lors du chargement des données Flandre:", error)
      this.primesData = {}
      this.currentCategory = '1'
    }
  }

  setupAutoSaveRestore() {
    // Restaurer les valeurs sauvegardées depuis la base de données
    if (this.simulationId) {
      // Récupérer les valeurs depuis les data attributes si elles existent
      const allCards = this.element.querySelectorAll('[data-controller*="flandre-prime-card"]')
      allCards.forEach(card => {
        const controller = this.application.getControllerForElementAndIdentifier(card, 'flandre-prime-card')
        if (controller) {
          // Laisser le temps au contrôleur de carte de se connecter
          setTimeout(() => controller.restoreValues(), 100)
        }
      })
    }
  }

  getCurrentCategory() {
    return this.currentCategory
  }

  getPrimesData() {
    return this.primesData
  }

  updateSectionTitle() {
    if (this.hasSectionTitleTarget) {
      const categoryNames = {
        '1': 'Catégorie 1',
        '2': 'Catégorie 2',
        '3': 'Catégorie 3',
        '4': 'Catégorie 4'
      }
      this.sectionTitleTarget.textContent = `Vos primes Flandre - ${categoryNames[this.currentCategory] || 'Catégorie 1'}`
    }
  }

  updateTotalGlobal() {
    if (!this.hasTotalGeneralTarget) return

    // Calculer le total de toutes les cartes
    const allResultElements = this.element.querySelectorAll('[data-flandre-prime-card-target="result"]')
    let total = 0

    allResultElements.forEach(element => {
      const value = parseFloat(element.textContent.replace(/[€\s,]/g, '.').replace(/[^\d.]/g, '')) || 0
      total += value
    })

    this.totalGeneralTarget.textContent = `${total.toFixed(2)} €`
    console.log("💰 Total Flandre mis à jour:", total.toFixed(2), "€")

    // Déclencher l'auto-save vers la base de données
    this.saveToDatabase()
  }

  // Méthode appelée par les cartes enfants pour notifier un changement
  cardUpdated() {
    this.updateTotalGlobal()
  }

  // Méthode pour changer de catégorie (appelée depuis l'interface d'éligibilité)
  changeCategory(newCategory) {
    console.log("🔄 Changement de catégorie Flandre:", this.currentCategory, "→", newCategory)

    this.currentCategory = newCategory
    window.flandreCurrentCategory = newCategory

    this.updateSectionTitle()

    // Notifier toutes les cartes du changement de catégorie
    this.element.dispatchEvent(new CustomEvent('flandre:category:changed', {
      detail: { category: newCategory },
      bubbles: true
    }))

    // Recalculer après le changement
    setTimeout(() => this.updateTotalGlobal(), 100)
  }

  saveToDatabase() {
    if (!this.simulationId) return

    // Collecter toutes les données des inputs
    const userInputs = {}
    const allInputs = this.element.querySelectorAll('input[data-slug], select[data-slug]')

    allInputs.forEach(input => {
      const slug = input.dataset.slug
      if (slug && input.value && input.value !== '0' && input.value !== '') {
        userInputs[slug] = input.value
      }
    })

    // Sauvegarder via API
    if (Object.keys(userInputs).length > 0) {
      fetch(`/fr/simulations/${this.simulationId}/update_prime_inputs`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ user_inputs: userInputs })
      })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          console.log("✅ Auto-save Flandre réussi:", data.total_amount, "€")
        }
      })
      .catch(error => {
        console.error("❌ Erreur auto-save Flandre:", error)
      })
    }
  }

  saveUserInput(event) {
    // Méthode appelée directement par les inputs pour un auto-save immédiat
    const input = event.target
    const slug = input.dataset.slug

    if (!slug || !this.simulationId) return

    const userInputs = { [slug]: input.value }

    fetch(`/fr/simulations/${this.simulationId}/update_prime_inputs`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ user_inputs: userInputs })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        console.log(`💾 Auto-save ${slug}:`, input.value, "→", data.total_amount, "€")
      }
    })
    .catch(error => {
      console.error("❌ Erreur auto-save:", error)
    })
  }
}
