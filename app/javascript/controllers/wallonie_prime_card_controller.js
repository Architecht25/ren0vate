import { Controller } from "@hotwired/stimulus"

// Controller pour une carte de prime individuelle Wallonie
export default class extends Controller {
  static targets = ["result"]
  static values = { 
    slug: String,
    category: String 
  }

  connect() {
    console.log(`🎯 Card controller connecté pour: ${this.slugValue}`)
    
    // Écouter les événements de changement global de catégorie
    this.boundGlobalUpdate = this.handleGlobalCategoryUpdate.bind(this)
    document.addEventListener('wallonie:globalCategoryUpdate', this.boundGlobalUpdate)
    
    // Calculer initialement
    this.calculate()
  }

  disconnect() {
    // Nettoyer les event listeners
    document.removeEventListener('wallonie:globalCategoryUpdate', this.boundGlobalUpdate)
  }

  handleGlobalCategoryUpdate(event) {
    this.categoryValue = event.detail.category
    this.calculate()
  }

  calculate() {
    if (!this.slugValue) {
      console.warn("❌ Aucun slug défini pour cette carte")
      return
    }

    const category = this.categoryValue || localStorage.getItem('selectedWallonieCategory') || 'r3'
    
    // Récupérer les données de prime
    const primesData = this.getPrimesData()
    const primeData = primesData[this.slugValue]
    
    if (!primeData) {
      console.warn(`❌ Données non trouvées pour la prime: ${this.slugValue}`)
      return
    }

    let totalAmount = 0

    // Récupérer toutes les valeurs d'inputs dans cette carte
    const inputs = this.element.querySelectorAll('input, select')
    
    inputs.forEach(input => {
      const value = this.getInputValue(input)
      if (value > 0) {
        const unitAmount = this.getUnitAmountForCategory(primeData, category)
        
        if (primeData.type_de_valeur === 'surface' || primeData.type_de_valeur === 'quantite') {
          // Multiplication par la quantité/surface
          totalAmount += value * unitAmount
        } else {
          // Valeur fixe (oui/non)
          totalAmount += unitAmount
        }
      }
    })

    // Mettre à jour l'affichage
    this.updateResult(totalAmount)
    
    // Notifier le controller parent
    this.notifyParentController()

    console.log(`💰 ${this.slugValue}: ${this.formatAmount(totalAmount)} (catégorie: ${category})`)
  }

  getInputValue(input) {
    if (input.type === 'number') {
      return parseFloat(input.value) || 0
    } else if (input.tagName === 'SELECT') {
      return parseFloat(input.value) || 0
    } else {
      return parseFloat(input.value) || 0
    }
  }

  getUnitAmountForCategory(primeData, category) {
    const valeurs = primeData.valeurs_par_categorie || {}
    
    // Essayer différents formats de clé de catégorie
    const possibleKeys = [
      `wallonie_${category}`,      // wallonie_r3
      category,                    // r3
      category.toUpperCase(),      // R3
      `wallonie_${category.toUpperCase()}` // wallonie_R3
    ]

    for (let key of possibleKeys) {
      if (valeurs[key] !== undefined) {
        const value = valeurs[key]
        
        // Si c'est un objet avec montant (structure Wallonie)
        if (typeof value === 'object' && value.montant !== undefined) {
          return parseFloat(value.montant) || 0
        }
        
        // Si c'est une valeur directe
        return parseFloat(value) || 0
      }
    }

    console.warn(`❌ Valeur non trouvée pour catégorie: ${category} dans`, valeurs)
    return 0
  }

  updateResult(amount) {
    if (this.hasResultTarget) {
      this.resultTarget.textContent = this.formatAmount(amount)
    }
  }

  formatAmount(amount) {
    return new Intl.NumberFormat('fr-BE', {
      style: 'currency',
      currency: 'EUR'
    }).format(amount)
  }

  notifyParentController() {
    // Trouver le controller parent et le notifier du changement
    const parentElement = this.element.closest('[data-controller*="wallonie-prime-calcul"]')
    if (parentElement) {
      const parentController = this.application.getControllerForElementAndIdentifier(parentElement, 'wallonie-prime-calcul')
      if (parentController && parentController.cardUpdated) {
        parentController.cardUpdated()
      }
    }
  }

  getPrimesData() {
    // Récupérer les données depuis le script JSON
    const primesDataElement = document.getElementById('wallonie-primes-data')
    if (primesDataElement) {
      try {
        return JSON.parse(primesDataElement.textContent)
      } catch (error) {
        console.error("❌ Erreur parsing primes data:", error)
        return {}
      }
    }
    return {}
  }

  // Méthodes d'action pour les inputs
  inputChanged(event) {
    this.calculate()
  }

  selectChanged(event) {
    this.calculate()
  }
}
