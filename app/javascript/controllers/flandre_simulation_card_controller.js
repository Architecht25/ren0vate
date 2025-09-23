import { Controller } from "@hotwired/stimulus"

// Contrôleur de carte dédié aux simulations Flandre post-login
// Séparé du contrôleur home page pour éviter les conflits
export default class extends Controller {
  static targets = ["total", "status", "input", "selectEtude", "selectType", "description"]
  static values = { slug: String }

  connect() {
    console.log(`🎯 Contrôleur Flandre Simulation Card connecté pour: ${this.slugValue}`)

    // Déclencher le calcul après un court délai pour s'assurer que tout est chargé
    setTimeout(() => this.calculate(), 100)
  }

  calculate() {
    console.log(`🔍 Calculate appelé pour ${this.slugValue}`)

    if (!this.slugValue) {
      console.warn("Pas de slug défini pour cette carte Flandre simulation")
      return
    }

    // Récupérer le contrôleur parent pour accéder aux données
    const parentController = this.getParentController()
    if (!parentController) {
      console.warn("Controller parent Flandre simulation non trouvé")
      return
    }

    const currentCategory = parentController.getCurrentCategory()
    const primesData = parentController.getPrimesData()
    console.log(`📊 Données pour ${this.slugValue} - catégorie: ${currentCategory}`)

    // Trouver la prime correspondante
    const prime = primesData[this.slugValue]
    if (!prime) {
      console.warn(`Prime Flandre non trouvée pour slug: ${this.slugValue}`)
      this.updateResult(0)
      return
    }

    // Récupérer les valeurs saisies
    const inputs = this.getInputValues()
    console.log(`🔢 Valeurs saisies pour ${this.slugValue}:`, inputs)

    // Calculer selon le type de prime
    let result = 0

    if (prime.calcul_type === 'forfait') {
      result = this.calculateForfait(prime, inputs, currentCategory)
    } else if (prime.calcul_type === 'variable') {
      result = this.calculateVariable(prime, inputs, currentCategory)
    } else if (prime.calcul_type === 'composite') {
      result = this.calculateComposite(prime, inputs, currentCategory)
    }

    console.log(`💰 Résultat calculé pour ${this.slugValue}: ${result}€`)
    this.updateResult(result)

    // Notifier le contrôleur parent qu'une carte a été mise à jour
    this.notifyParentController()
  }

  calculateForfait(prime, inputs, category) {
    const categoryData = prime.valeurs_par_categorie?.[category]
    if (!categoryData) return 0

    let total = 0

    // Parcourir tous les inputs pour les primes forfaitaires
    Object.keys(inputs).forEach(inputKey => {
      const value = inputs[inputKey]
      if (value && value > 0) {
        const montant = categoryData.forfait || categoryData.montant || 0
        total += montant * value
      }
    })

    return Math.round(total)
  }

  calculateVariable(prime, inputs, category) {
    const categoryData = prime.valeurs_par_categorie?.[category]
    if (!categoryData) return 0

    let total = 0

    // Parcourir tous les inputs pour les primes variables
    Object.keys(inputs).forEach(inputKey => {
      const value = inputs[inputKey]
      if (value && value > 0) {
        const montantParUnite = categoryData.montant_par_unite || categoryData.montant || 0
        total += montantParUnite * value
      }
    })

    return Math.round(total)
  }

  calculateComposite(prime, inputs, category) {
    const categoryData = prime.valeurs_par_categorie?.[category]
    if (!categoryData) return 0

    let total = 0

    // Logique composite spécifique selon le slug
    if (this.slugValue.includes('isolation_murs_cat12')) {
      // Logique spéciale pour isolation murs cat 1-2
      const typeIsolation = inputs.type_isolation || 'exterieur'
      const surface = parseFloat(inputs.surface) || 0

      const tarifs = categoryData.tarifs?.[typeIsolation]
      if (tarifs && surface > 0) {
        total = tarifs.montant_par_m2 * surface
      }
    } else if (this.slugValue.includes('warmtepomp')) {
      // Logique pour pompe à chaleur
      const typeInstallation = inputs.type_installation || 'standard'
      const etude = inputs.etude_prealable || false

      let montantBase = categoryData.montant_base || 0
      if (etude) {
        montantBase += categoryData.bonus_etude || 0
      }

      const multiplicateur = categoryData.multiplicateurs?.[typeInstallation] || 1
      total = montantBase * multiplicateur
    } else {
      // Logique composite générique
      Object.keys(inputs).forEach(inputKey => {
        const value = inputs[inputKey]
        if (value && value > 0) {
          const montant = categoryData.montant || 0
          total += montant * value
        }
      })
    }

    return Math.round(total)
  }

  getInputValues() {
    const inputs = {}

    // Récupérer toutes les valeurs des inputs dans cette carte
    const allInputs = this.element.querySelectorAll('input, select')
    allInputs.forEach(input => {
      if (input.name || input.dataset.slug) {
        const key = input.name || input.dataset.slug
        if (input.type === 'checkbox') {
          inputs[key] = input.checked ? 1 : 0
        } else if (input.type === 'number') {
          inputs[key] = parseFloat(input.value) || 0
        } else {
          inputs[key] = input.value
        }
      }
    })

    return inputs
  }

  updateResult(amount) {
    if (this.hasTotalTarget) {
      this.totalTarget.textContent = `${amount.toLocaleString('fr-FR')} €`

      // Animation visuelle
      this.totalTarget.classList.add('updated')
      setTimeout(() => {
        this.totalTarget.classList.remove('updated')
      }, 300)
    }

    // Mettre à jour le statut
    if (this.hasStatusTarget) {
      if (amount > 0) {
        this.statusTarget.innerHTML = '<i class="bi bi-check-circle text-success me-2"></i>Prime calculée'
        this.statusTarget.className = 'badge bg-success'
      } else {
        this.statusTarget.innerHTML = '<i class="bi bi-dash-circle text-muted me-2"></i>Non applicable'
        this.statusTarget.className = 'badge bg-secondary'
      }
    }
  }

  getParentController() {
    // Chercher le contrôleur parent flandre-simulation pour les simulations
    const parentElement = this.element.closest('[data-controller*="flandre-simulation"]')
    if (parentElement) {
      return this.application.getControllerForElementAndIdentifier(parentElement, 'flandre-simulation')
    }
    return null
  }

  notifyParentController() {
    // Notifier le contrôleur parent qu'une carte a été mise à jour
    const parentController = this.getParentController()
    if (parentController && typeof parentController.cardUpdated === 'function') {
      parentController.cardUpdated()
    }
  }

  // Actions pour les différents types d'inputs
  onInputChange() {
    this.calculate()
  }

  onSelectChange() {
    this.calculate()
  }

  calculateAudit() { this.calculate() }
  calculateBonus() { this.calculate() }
  calculateSurface() { this.calculate() }
  onTypeChange() { this.calculate() }
  onEtudeChange() { this.calculate() }
}
