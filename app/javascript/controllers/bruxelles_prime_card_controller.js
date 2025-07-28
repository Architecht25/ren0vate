import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["total"]
  static values = { category: String, slug: String }

  connect() {
    console.log("🎯 Contrôleur Bruxelles Prime Card connecté")

    // Récupérer la catégorie actuelle depuis le contrôleur parent
    this.currentCategory = this.getCurrentCategoryFromParent()

    // Écouter les changements de catégorie
    this.element.addEventListener('bruxelles:category:changed', this.updateCategory.bind(this))

    // Calculer le montant initial
    this.calculate()
  }

  disconnect() {
    this.element.removeEventListener('bruxelles:category:changed', this.updateCategory.bind(this))
  }

  updateCategory(event) {
    this.currentCategory = event.detail?.categorie || "bruxelles_cat3"
    console.log("🔄 Carte Prime Bruxelles - Nouvelle catégorie:", this.currentCategory)
    this.calculate()
  }

  getCurrentCategoryFromParent() {
    const parentController = this.getParentController()
    if (parentController && parentController.getCurrentCategory) {
      return parentController.getCurrentCategory()
    }
    
    // Fallback vers localStorage
    const storedCategory = localStorage.getItem("bruxellesCategorieEstimee")
    if (storedCategory) {
      const categoryMap = {
        "1": "bruxelles_cat1",
        "2": "bruxelles_cat2", 
        "3": "bruxelles_cat3"
      }
      return categoryMap[storedCategory] || "bruxelles_cat3"
    }
    
    return "bruxelles_cat3" // Catégorie par défaut
  }

  calculate() {
    // Si c'est une carte composite (globale), utiliser le calcul composite
    if (this.isCompositeCard()) {
      this.calculateComposite()
      return
    }

    // Sinon, calcul simple
    this.calculateSimple()
  }

  calculateSimple() {
    let total = 0

    // Récupérer tous les inputs de la carte
    const inputs = this.element.querySelectorAll('input, select')
    
    inputs.forEach(input => {
      const value = this.getInputValue(input)
      if (value > 0) {
        // Calculer selon le type d'input et la catégorie
        const montant = this.calculateInputAmount(input, value)
        total += montant
      }
    })

    // Mettre à jour l'affichage
    this.updateTotal(total)

    // Notifier le parent
    this.notifyParent()
  }

  calculateComposite() {
    // Pour les cartes composites qui contiennent plusieurs primes
    // Chaque section a ses propres inputs et résultats
    let totalGeneral = 0

    const sections = this.getCompositeSections()
    
    sections.forEach(section => {
      let sectionTotal = 0
      
      section.inputs.forEach(inputSelector => {
        const input = this.element.querySelector(inputSelector)
        if (input) {
          const value = this.getInputValue(input)
          if (value > 0) {
            const montant = this.calculateSectionAmount(section.type, value)
            sectionTotal += montant
          }
        }
      })

      // Mettre à jour le résultat de la section
      if (section.resultSelector) {
        const resultElement = this.element.querySelector(section.resultSelector)
        if (resultElement) {
          resultElement.textContent = `${sectionTotal.toLocaleString('fr-BE')} €`
        }
      }

      totalGeneral += sectionTotal
    })

    // Mettre à jour le total de la carte
    this.updateTotal(totalGeneral)

    // Notifier le parent
    this.notifyParent()
  }

  getInputValue(input) {
    if (input.type === 'checkbox' || input.type === 'radio') {
      return input.checked ? (parseFloat(input.value) || 1) : 0
    }
    if (input.tagName === 'SELECT') {
      return parseFloat(input.value) || 0
    }
    return parseFloat(input.value) || 0
  }

  calculateInputAmount(input, value) {
    // Récupérer le type de calcul depuis l'attribut data ou le placeholder
    const calculType = this.getCalculationType(input)
    const baseAmount = this.getBaseAmount(input, calculType)
    
    // Appliquer le multiplicateur de catégorie
    const multiplier = this.getCategoryMultiplier()
    
    let montant = 0
    
    switch (calculType) {
      case 'montant_fixe':
        montant = value > 0 ? baseAmount * multiplier : 0
        break
      case 'par_m2':
        montant = value * baseAmount * multiplier
        break
      case 'par_unite':
        montant = value * baseAmount * multiplier
        break
      case 'pourcentage':
        const maxAmount = this.getMaxAmount(input)
        montant = Math.min((value * baseAmount / 100) * multiplier, maxAmount)
        break
      default:
        montant = value * baseAmount * multiplier
    }
    
    return Math.round(montant)
  }

  calculateSectionAmount(sectionType, value) {
    const baseAmounts = this.getSectionBaseAmounts()
    const baseAmount = baseAmounts[sectionType] || 0
    const multiplier = this.getCategoryMultiplier()
    
    return Math.round(value * baseAmount * multiplier)
  }

  getCalculationType(input) {
    // Déterminer le type de calcul selon les attributs ou le contexte
    if (input.dataset.calculType) {
      return input.dataset.calculType
    }
    
    const placeholder = input.placeholder?.toLowerCase() || ''
    
    if (placeholder.includes('m²') || placeholder.includes('surface')) {
      return 'par_m2'
    }
    if (placeholder.includes('nombre') || placeholder.includes('unité')) {
      return 'par_unite'
    }
    if (placeholder.includes('montant') || placeholder.includes('coût')) {
      return 'pourcentage'
    }
    if (input.type === 'checkbox' || (input.tagName === 'SELECT' && input.value === '1')) {
      return 'montant_fixe'
    }
    
    return 'par_unite' // Par défaut
  }

  getBaseAmount(input, calculType) {
    // Montants de base selon le type de travaux et la carte
    const baseAmounts = {
      // Services et études (Prime A)
      'audit_maison': 650,
      'audit_batiment': 1200,
      'audit_logement': 450,
      'accompagnement': 500,
      'conseiller': 300,

      // Isolation (Prime C)
      'isolation_toiture_m2': 25,
      'isolation_murs_m2': 30,
      'isolation_sol_m2': 20,

      // Menuiseries (Prime H)
      'fenetres_m2': 85,
      'portes_m2': 120,

      // Chauffage (Prime F)
      'chaudiere': 1500,
      'pac': 4500,
      'ventilation': 3500,
      'solaire_thermique': 2500,

      // Électricité (Prime J)
      'electrique_point': 50,
      'photovoltaique_kwc': 300
    }

    // Essayer de déterminer le type depuis l'ID ou les classes
    const inputId = input.id || ''
    const inputClasses = input.className || ''
    
    for (const [key, amount] of Object.entries(baseAmounts)) {
      if (inputId.includes(key) || inputClasses.includes(key)) {
        return amount
      }
    }

    // Valeur par défaut selon le type de calcul
    switch (calculType) {
      case 'montant_fixe': return 500
      case 'par_m2': return 25
      case 'par_unite': return 100
      case 'pourcentage': return 20
      default: return 100
    }
  }

  getMaxAmount(input) {
    // Montant maximum pour les calculs en pourcentage
    return parseFloat(input.dataset.maxAmount) || 5000
  }

  getCategoryMultiplier() {
    // Facteur multiplicateur selon la catégorie de revenus
    const multipliers = {
      "bruxelles_cat1": 0.8,    // Entreprises, ASBL
      "bruxelles_cat2": 0.8,    // Syndics
      "bruxelles_cat3": 1.0     // Particuliers (revenus faibles), AIS
    }

    return multipliers[this.currentCategory] || 1.0
  }

  isCompositeCard() {
    // Vérifier si c'est une carte composite
    const compositeCategories = [
      'prime-a', 'prime-b', 'prime-c', 'prime-d', 'prime-e',
      'prime-f', 'prime-g', 'prime-h', 'prime-i', 'prime-j',
      'prime-kl', 'prime-m', 'prime-z'
    ]
    
    return compositeCategories.includes(this.categoryValue)
  }

  getCompositeSections() {
    // Définir les sections composites selon la carte
    // À adapter selon la structure réelle des cartes
    return [
      {
        type: 'section1',
        inputs: ['[data-section="1"] input', '[data-section="1"] select'],
        resultSelector: '[data-section="1"] .result'
      }
    ]
  }

  getSectionBaseAmounts() {
    // Montants de base pour les sections composites
    return {
      'section1': 100,
      'section2': 200,
      'section3': 300
    }
  }

  updateTotal(total) {
    if (this.hasTotalTarget) {
      this.totalTarget.textContent = `${total.toLocaleString('fr-BE')} €`

      // Ajouter une classe pour l'animation
      this.totalTarget.classList.add('updated')
      setTimeout(() => {
        this.totalTarget.classList.remove('updated')
      }, 300)
    }
  }

  notifyParent() {
    // Notifier le contrôleur parent qu'une carte a été mise à jour
    const parentController = this.getParentController()
    if (parentController && parentController.cardUpdated) {
      parentController.cardUpdated()
    }
  }

  getParentController() {
    // Trouver le controller parent bruxelles-prime-calcul
    let parent = this.element.parentElement
    while (parent) {
      if (parent.hasAttribute('data-controller') &&
          parent.getAttribute('data-controller').includes('bruxelles-prime-calcul')) {
        return this.application.getControllerForElementAndIdentifier(parent, 'bruxelles-prime-calcul')
      }
      parent = parent.parentElement
    }
    return null
  }

  // Méthode pour recalculer (appelée depuis le controller parent)
  recalculate() {
    this.calculate()
  }

  // Actions pour les événements de changement
  calculateAudit() { this.calculate() }
  calculateToiture() { this.calculate() }
  calculateIsolation() { this.calculate() }
  calculateMenuiseries() { this.calculate() }
  calculateChauffage() { this.calculate() }
  calculateVentilation() { this.calculate() }
  calculateElectricite() { this.calculate() }
  calculateRenouvelables() { this.calculate() }
  calculateAutres() { this.calculate() }
}
