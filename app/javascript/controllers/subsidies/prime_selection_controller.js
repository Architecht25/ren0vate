// Stimulus controller for prime selection and prioritization
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "simulationTotal",
    "simulationCount",
    "selectedTotal",
    "selectedCount",
    "estimatedInvestment",
    "remainingCost",
    "recommendations",
    "primesList"
  ]

  connect() {
    this.selectedPrimes = new Set()
    this.primeData = this.extractPrimeData()

    // Initialiser avec les primes pré-cochées
    this.initializePreselectedPrimes()
    this.updateTotals()
    this.updateRecommendations()
  }

  extractPrimeData() {
    const primes = {}
    const primeItems = this.element.querySelectorAll('.prime-item')

    primeItems.forEach(item => {
      const slug = item.dataset.primeSlug
      const amount = parseInt(item.dataset.primeAmount)
      const name = item.querySelector('h6').textContent.trim()
      const category = item.querySelector('.text-muted').textContent.split('•')[0].trim()

      primes[slug] = {
        slug,
        name,
        amount,
        category,
        element: item,
        estimatedInvestment: amount * 2.5 // Estimation: prime = 40% du coût
      }
    })

    return primes
  }

  initializePreselectedPrimes() {
    const checkboxes = this.element.querySelectorAll('input[type="checkbox"]:checked')
    checkboxes.forEach(checkbox => {
      this.selectedPrimes.add(checkbox.dataset.primeSlug)
    })
  }

  togglePrime(event) {
    const checkbox = event.target
    const primeSlug = checkbox.dataset.primeSlug
    const primeItem = checkbox.closest('.prime-item')

    if (checkbox.checked) {
      this.selectedPrimes.add(primeSlug)
      primeItem.classList.remove('border-light')
      primeItem.classList.add('border-success')

      // Animation d'ajout
      primeItem.style.transform = 'scale(1.02)'
      setTimeout(() => {
        primeItem.style.transform = 'scale(1)'
      }, 150)

    } else {
      this.selectedPrimes.delete(primeSlug)
      primeItem.classList.remove('border-success')
      primeItem.classList.add('border-light')

      // Animation de retrait
      primeItem.style.opacity = '0.7'
      setTimeout(() => {
        primeItem.style.opacity = '1'
      }, 150)
    }

    this.updateTotals()
    this.updateRecommendations()
    this.highlightOptimalCombinations()
  }

  updateTotals() {
    let selectedTotal = 0
    let estimatedInvestment = 0

    this.selectedPrimes.forEach(slug => {
      const prime = this.primeData[slug]
      if (prime) {
        selectedTotal += prime.amount
        estimatedInvestment += prime.estimatedInvestment
      }
    })

    const remainingCost = estimatedInvestment - selectedTotal

    // Mettre à jour l'interface
    this.selectedTotalTargets.forEach(target => {
      target.textContent = `${selectedTotal.toLocaleString()}€`
    })

    this.selectedCountTargets.forEach(target => {
      target.textContent = this.selectedPrimes.size
    })

    this.estimatedInvestmentTargets.forEach(target => {
      target.textContent = `${estimatedInvestment.toLocaleString()}€`
    })

    this.remainingCostTargets.forEach(target => {
      target.textContent = `${remainingCost.toLocaleString()}€`
      target.className = remainingCost > 0 ? 'text-warning' : 'text-success'
    })
  }

  updateRecommendations() {
    const recommendations = this.generateSmartRecommendations()

    if (this.hasRecommendationsTarget) {
      this.recommendationsTarget.innerHTML = recommendations.map(rec =>
        `<div class="mb-2"><strong>${rec.type}:</strong> ${rec.message}</div>`
      ).join('')
    }
  }

  generateSmartRecommendations() {
    const recommendations = []
    const selectedSlugs = Array.from(this.selectedPrimes)
    const selectedCategories = selectedSlugs.map(slug =>
      this.primeData[slug]?.category
    ).filter(Boolean)

    // Recommandation d'ordre
    if (selectedSlugs.some(slug => slug.includes('audit')) && selectedSlugs.length > 1) {
      recommendations.push({
        type: "Optimisation",
        message: "Excellent ! L'audit PAE en premier maximise vos autres primes."
      })
    }

    // Recommandation de groupement
    if (selectedCategories.includes('Isolation') && selectedCategories.includes('Ventilation')) {
      recommendations.push({
        type: "Timing",
        message: "Grouper isolation + ventilation réduit les coûts de chantier de 15-20%."
      })
    }

    // Recommandation budgétaire
    const totalSelected = selectedSlugs.reduce((sum, slug) =>
      sum + (this.primeData[slug]?.amount || 0), 0
    )

    if (totalSelected > 15000) {
      recommendations.push({
        type: "Budget",
        message: "Budget important : prévoir étalement sur 18-24 mois pour optimiser la trésorerie."
      })
    } else if (totalSelected < 5000) {
      recommendations.push({
        type: "Opportunité",
        message: "Budget restant disponible : considérez d'autres primes complémentaires."
      })
    }

    // Recommandation par défaut
    if (recommendations.length === 0) {
      recommendations.push({
        type: "Conseil",
        message: "Votre sélection semble équilibrée. Vérifiez les délais et conditions."
      })
    }

    return recommendations
  }

  highlightOptimalCombinations() {
    // Logique pour mettre en évidence les combinaisons optimales
    const auditSelected = Array.from(this.selectedPrimes).some(slug => slug.includes('audit'))

    if (!auditSelected) {
      // Suggérer visuellement l'audit si pas sélectionné
      const auditCheckbox = this.element.querySelector('[data-prime-slug*="audit"]')
      if (auditCheckbox) {
        const auditCard = auditCheckbox.closest('.prime-item')
        auditCard.style.background = 'linear-gradient(45deg, #fff3cd 0%, #ffffff 100%)'
        setTimeout(() => {
          auditCard.style.background = ''
        }, 2000)
      }
    }
  }

  saveSelection(event) {
    event.preventDefault()

    const selectionData = {
      selected_primes: Array.from(this.selectedPrimes),
      total_amount: Array.from(this.selectedPrimes).reduce((sum, slug) =>
        sum + (this.primeData[slug]?.amount || 0), 0
      ),
      timestamp: new Date().toISOString()
    }

    // TODO: Sauvegarder en base de données

    // Feedback visuel
    const button = event.target
    const originalText = button.innerHTML
    button.innerHTML = '<i class="bi bi-check me-1"></i>Sauvegardé !'
    button.classList.add('btn-success')
    button.classList.remove('btn-primary')

    setTimeout(() => {
      button.innerHTML = originalText
      button.classList.remove('btn-success')
      button.classList.add('btn-primary')
    }, 2000)
  }

  generatePlan(event) {
    event.preventDefault()

    const selectedPrimes = Array.from(this.selectedPrimes).map(slug => this.primeData[slug])

    // Générer un planning intelligent
    const plan = this.generateOptimalPlan(selectedPrimes)

    // TODO: Afficher le planning dans une modal ou rediriger
    alert("Planning généré ! (Fonctionnalité à implémenter)")
  }

  generateOptimalPlan(primes) {
    // Logique de génération de planning optimisé
    const phases = []

    // Phase 1: Audit (si présent)
    const auditPrimes = primes.filter(p => p.category.includes('audit'))
    if (auditPrimes.length > 0) {
      phases.push({
        name: "Phase 1: Audit énergétique",
        duration: "2-3 semaines",
        primes: auditPrimes
      })
    }

    // Phase 2: Gros œuvre (isolation)
    const isolationPrimes = primes.filter(p => p.category.includes('Isolation'))
    if (isolationPrimes.length > 0) {
      phases.push({
        name: "Phase 2: Isolation",
        duration: "4-6 semaines",
        primes: isolationPrimes
      })
    }

    // Phase 3: Équipements
    const equipmentPrimes = primes.filter(p =>
      !p.category.includes('audit') && !p.category.includes('Isolation')
    )
    if (equipmentPrimes.length > 0) {
      phases.push({
        name: "Phase 3: Équipements",
        duration: "3-4 semaines",
        primes: equipmentPrimes
      })
    }

    return phases
  }

  exportDocuments(event) {
    event.preventDefault()

    const selectedSlugs = Array.from(this.selectedPrimes)

    // TODO: Générer les documents pour les primes sélectionnées
    alert("Export des documents en cours... (Fonctionnalité à implémenter)")
  }

  resetSelection(event) {
    event.preventDefault()

    // Tout sélectionner
    const checkboxes = this.element.querySelectorAll('input[type="checkbox"]')
    checkboxes.forEach(checkbox => {
      if (!checkbox.checked) {
        checkbox.checked = true
        this.togglePrime({ target: checkbox })
      }
    })
  }
}
