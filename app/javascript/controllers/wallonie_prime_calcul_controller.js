import { Controller } from "@hotwired/stimulus"

// Controller principal pour le calcul global des primes Wallonie
export default class extends Controller {
  static targets = ["totalGlobal", "sectionTitle", "categoryIndicator"]
  static values = { 
    category: String,
    primes: Object
  }

  connect() {
    console.log("🎯 Controller Wallonie Prime Calcul connecté")
    
    // Initialiser les données des primes depuis le script JSON
    this.initializePrimesData()
    
    // Écouter les changements de catégorie
    this.listenForCategoryChanges()
    
    // Calculer le total initial
    this.updateGlobalTotal()
  }

  initializePrimesData() {
    const primesDataElement = document.getElementById('wallonie-primes-data')
    if (primesDataElement) {
      try {
        this.primesValue = JSON.parse(primesDataElement.textContent)
        console.log("📊 Données des primes Wallonie chargées:", this.primesValue)
      } catch (error) {
        console.error("❌ Erreur lors du chargement des données des primes:", error)
        this.primesValue = {}
      }
    }

    // Récupérer la catégorie depuis localStorage
    this.categoryValue = localStorage.getItem('selectedWallonieCategory') || 'r3'
    this.updateCategoryDisplay()
  }

  listenForCategoryChanges() {
    // Écouter les événements de changement de catégorie
    document.addEventListener('wallonie:categoryChanged', (event) => {
      this.categoryValue = event.detail.category
      this.updateCategoryDisplay()
      this.updateGlobalTotal()
      
      // Notifier toutes les cartes du changement de catégorie
      this.notifyCardsOfCategoryChange()
    })

    // Écouter les changements dans localStorage
    window.addEventListener('storage', (event) => {
      if (event.key === 'selectedWallonieCategory') {
        this.categoryValue = event.newValue || 'r3'
        this.updateCategoryDisplay()
        this.notifyCardsOfCategoryChange()
      }
    })
  }

  updateCategoryDisplay() {
    const categoryMap = {
      'r1': 'R1 (Revenus très faibles)',
      'r2': 'R2 (Revenus faibles)', 
      'r3': 'R3 (Revenus moyens)',
      'r4': 'R4 (Revenus élevés)',
      'r5': 'R5 (Revenus très élevés)'
    }

    if (this.hasSectionTitleTarget) {
      this.sectionTitleTarget.textContent = `Vos primes Wallonie - ${categoryMap[this.categoryValue] || 'Catégorie R1-R5'}`
    }
    
    if (this.hasCategoryIndicatorTarget) {
      this.categoryIndicatorTarget.textContent = this.categoryValue.toUpperCase()
      this.categoryIndicatorTarget.className = `badge bg-success fs-6`
    }
  }

  notifyCardsOfCategoryChange() {
    // Dispatcher un événement pour toutes les cartes
    const event = new CustomEvent('wallonie:globalCategoryUpdate', {
      detail: { 
        category: this.categoryValue,
        primes: this.primesValue 
      }
    })
    document.dispatchEvent(event)
  }

  updateGlobalTotal() {
    let total = 0
    
    // Récupérer tous les montants des cartes
    const cards = document.querySelectorAll('[data-controller*="wallonie-prime-card"]')
    cards.forEach(card => {
      const resultElement = card.querySelector('[data-wallonie-prime-card-target="result"]')
      if (resultElement) {
        const amount = parseFloat(resultElement.textContent.replace(/[€\s,]/g, '')) || 0
        total += amount
      }
    })
    
    if (this.hasTotalGlobalTarget) {
      this.totalGlobalTarget.textContent = this.formatAmount(total)
    }
    
    console.log(`💰 Total global Wallonie: ${this.formatAmount(total)}`)
  }

  formatAmount(amount) {
    return new Intl.NumberFormat('fr-BE', {
      style: 'currency',
      currency: 'EUR'
    }).format(amount)
  }

  // Méthode appelée par les cartes pour mettre à jour le total
  cardUpdated() {
    this.updateGlobalTotal()
  }

  // Méthode pour changer de catégorie (appelée depuis l'interface d'éligibilité)
  changeCategory(newCategory) {
    this.categoryValue = newCategory
    localStorage.setItem('selectedWallonieCategory', newCategory)
    this.updateCategoryDisplay()
    this.notifyCardsOfCategoryChange()
  }

  getCurrentCategory() {
    return this.categoryValue
  }

  getPrimesData() {
    return this.primesValue
  }
}
