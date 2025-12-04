import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["categoryBody", "globalSummary", "categoriesSummary", "totalEstimate"]

  connect() {
    console.log("Bruxelles Aides Estimation controller connected")
    this.calculations = {}
    this.categoryData = this.loadCategoryData()
  }

  loadCategoryData() {
    return {
      transition_economique: {
        consultance_transition: { rate: 0.50, max: 25000 },
        investissements_transition: { rate: 0.30, max: 200000 }
      },
      investissements: {
        materiels_equipements: { rate: 0.05, max: 200000 },
        travaux_immobiliers: { rate: 0.05, max: 100000 },
        conformite_reglementaire: { rate: 0.40, max: 100000 }
      },
      recrutement_formation: {
        aide_embauche: { fixed: 6000, max_units: 10 },
        formation_personnel: { rate: 0.40, max: 25000 }
      },
      expertise_services: {
        consultance_generale: { rate: 0.25, max: 12500 },
        etudes_audits: { rate: 0.25, max: 25000 }
      },
      nuisances_chantier: {
        perte_ca: { rate: 0.80, max: 25000 },
        duree_chantier: { multiplier: true }
      }
    }
  }

  toggleCategory(event) {
    const checkbox = event.target
    const category = checkbox.dataset.bruxellesAidesEstimationCategoryParam
    const card = checkbox.closest('[data-category]')
    const body = card.querySelector('[data-bruxelles-aides-estimation-target="categoryBody"]')

    if (checkbox.checked) {
      body.style.display = 'block'
      this.calculations[category] = {}
    } else {
      body.style.display = 'none'
      delete this.calculations[category]
      // Reset inputs
      const inputs = body.querySelectorAll('input[type="number"]')
      inputs.forEach(input => input.value = '')
      // Hide result
      const result = body.querySelector('.estimation-result')
      if (result) result.style.display = 'none'
    }

    this.updateGlobalSummary()
  }

  calculateEstimate(event) {
    const input = event.target
    const card = input.closest('[data-category]')
    const category = card.dataset.category
    const subcategory = input.dataset.subcategory
    const value = parseFloat(input.value) || 0

    if (!this.calculations[category]) {
      this.calculations[category] = {}
    }

    this.calculations[category][subcategory] = value

    // Calculate category total
    const categoryTotal = this.calculateCategoryTotal(category)

    // Update category display
    const result = card.querySelector('.estimation-result')
    const amountSpan = result.querySelector('.estimation-amount')

    if (categoryTotal > 0) {
      result.style.display = 'block'
      amountSpan.textContent = this.formatCurrency(categoryTotal)
    } else {
      result.style.display = 'none'
    }

    this.updateGlobalSummary()
  }

  calculateCategoryTotal(category) {
    const categoryCalcs = this.calculations[category] || {}
    const categoryRules = this.categoryData[category] || {}
    let total = 0

    Object.keys(categoryCalcs).forEach(subcategory => {
      const amount = categoryCalcs[subcategory]
      const rule = categoryRules[subcategory]

      if (!rule || amount <= 0) return

      let subTotal = 0

      if (rule.fixed) {
        // Fixed amount per unit (like recruitment)
        subTotal = Math.min(amount * rule.fixed, (rule.max_units || Infinity) * rule.fixed)
      } else if (rule.rate) {
        // Percentage calculation
        subTotal = Math.min(amount * rule.rate, rule.max || Infinity)
      }

      total += subTotal
    })

    // Special case for nuisances with duration multiplier
    if (category === 'nuisances_chantier' && categoryCalcs.duree_chantier > 0) {
      const duration = categoryCalcs.duree_chantier
      if (duration >= 3) {
        total *= 1.2 // 20% bonus for long projects
      }
    }

    return Math.round(total)
  }

  updateGlobalSummary() {
    const activeCategories = Object.keys(this.calculations)

    if (activeCategories.length === 0) {
      this.globalSummaryTarget.style.display = 'none'
      return
    }

    let grandTotal = 0
    let summaryHTML = ''

    activeCategories.forEach(category => {
      const categoryTotal = this.calculateCategoryTotal(category)
      if (categoryTotal > 0) {
        grandTotal += categoryTotal
        const categoryName = this.getCategoryDisplayName(category)
        summaryHTML += `
          <div class="d-flex justify-content-between mb-2">
            <span><strong>${categoryName}</strong></span>
            <span class="text-success">${this.formatCurrency(categoryTotal)}</span>
          </div>
        `
      }
    })

    if (grandTotal > 0) {
      this.globalSummaryTarget.style.display = 'block'
      this.categoriesSummaryTarget.innerHTML = summaryHTML
      this.totalEstimateTarget.textContent = this.formatCurrency(grandTotal)
    } else {
      this.globalSummaryTarget.style.display = 'none'
    }
  }

  getCategoryDisplayName(category) {
    const names = {
      transition_economique: 'Transition économique',
      investissements: 'Investissements',
      recrutement_formation: 'Recrutement & Formation',
      expertise_services: 'Expertise & Services',
      nuisances_chantier: 'Nuisances chantier'
    }
    return names[category] || category
  }

  formatCurrency(amount) {
    return new Intl.NumberFormat('fr-BE', {
      style: 'currency',
      currency: 'EUR',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(amount)
  }
}
