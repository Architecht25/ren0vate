import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "result", "typeMur"]
  static values = { slug: String }

  connect() {
    console.log("🎯 Contrôleur Flandre Prime Card connecté pour:", this.slugValue)

    // Écouter les changements de catégorie
    this.element.addEventListener('flandre:category:changed', this.recalculate.bind(this))

    // Calculer le montant initial
    this.calculate()
  }

  disconnect() {
    this.element.removeEventListener('flandre:category:changed', this.recalculate.bind(this))
  }

  recalculate() {
    // Attendre un court instant pour que les données de catégorie soient mises à jour
    setTimeout(() => this.calculate(), 50)
  }

  calculate() {
    if (!this.slugValue) {
      console.warn("Pas de slug défini pour cette carte Flandre")
      return
    }

    // Récupérer le contrôleur parent pour accéder aux données
    const parentController = this.getParentController()
    if (!parentController) {
      console.warn("Controller parent Flandre non trouvé")
      return
    }

    const currentCategory = parentController.getCurrentCategory()
    const primesData = parentController.getPrimesData()

    // Trouver la prime correspondante
    const prime = primesData[this.slugValue]
    if (!prime) {
      console.warn(`Prime Flandre non trouvée pour slug: ${this.slugValue}`)
      this.updateResult(0)
      return
    }

    // Calculer selon le type de calcul
    const calculData = prime.valeurs_par_categorie?.[currentCategory]
    if (!calculData) {
      console.warn(`Données de calcul non trouvées pour ${this.slugValue} - catégorie ${currentCategory}`)
      // Vérifier si la prime existe pour d'autres catégories
      const availableCategories = Object.keys(prime.valeurs_par_categorie || {})
      if (availableCategories.length > 0) {
        console.info(`Prime ${this.slugValue} disponible seulement pour: ${availableCategories.join(', ')}`)
        // Afficher 0€ pour les primes non disponibles
        this.updateResult(0)
        return
      }
      return
    }

    let total = 0

    // Logique de calcul selon le type
    switch (calculData.type) {
      case 'montant_fixe':
        total = this.calculateMontantFixe(calculData)
        break
      case 'montant_m2':
        total = this.calculateMontantM2(calculData)
        break
      case 'montant_m2_et_limite':
        total = this.calculateMontantM2AvecLimite(calculData)
        break
      case 'montant_variable_m2_et_limite':
        total = this.calculateMontantVariableM2(calculData)
        break
      case 'forfait_et_plafond_facture':
        total = this.calculateForfaitEtPlafond(calculData)
        break
      case 'forfait':
        total = this.calculateForfait(calculData)
        break
      case 'pourcentage':
        total = this.calculatePourcentage(calculData)
        break
      default:
        console.warn(`Type de calcul non pris en charge pour Flandre: ${calculData.type}`)
        total = 0
    }

    this.updateResult(total)
  }

  calculateMontantFixe(calculData) {
    // Vérifier si c'est un checkbox/select qui détermine l'activation
    if (this.hasInputTarget) {
      const input = this.inputTarget
      const isSelected = input.type === 'checkbox' ? input.checked : (input.value === "1" || input.value !== "")
      return isSelected ? (calculData.forfait || calculData.montant || 0) : 0
    }
    return calculData.forfait || calculData.montant || 0
  }

  calculateMontantM2(calculData) {
    if (!this.hasInputTarget) return 0

    const surface = parseFloat(this.inputTarget.value) || 0
    const montantParM2 = calculData.montant_m2 || calculData.montant_par_m2 || 0
    return surface * montantParM2
  }

  calculateMontantM2AvecLimite(calculData) {
    if (!this.hasInputTarget) return 0

    const surface = parseFloat(this.inputTarget.value) || 0
    const montantParM2 = calculData.montant_m2 || calculData.montant_par_m2 || 0
    const surfaceMax = calculData.surface_max || Infinity
    const surfaceLimitee = Math.min(surface, surfaceMax)

    return surfaceLimitee * montantParM2
  }

  calculateMontantVariableM2(calculData) {
    if (!this.hasInputTarget) return 0

    const surface = parseFloat(this.inputTarget.value) || 0

    // Récupérer le type de mur sélectionné
    let typeMur = "exterieur" // défaut
    if (this.hasTypeMurTarget) {
      typeMur = this.typeMurTarget.value || "exterieur"
    }

    const montantParM2 = calculData.montants_m2?.[typeMur] || 0
    const surfaceMax = calculData.surface_max || Infinity
    const surfaceLimitee = Math.min(surface, surfaceMax)

    console.log(`🏗️ Calcul variable m² - Type: ${typeMur}, Surface: ${surfaceLimitee}m², Montant/m²: ${montantParM2}€`)

    return surfaceLimitee * montantParM2
  }

  calculateForfaitEtPlafond(calculData) {
    if (!this.hasInputTarget) return 0

    const montantFacture = parseFloat(this.inputTarget.value) || 0

    if (this.slugValue === "warmtepompboiler") {
      // Chauffe-eau thermodynamique
      const forfait = calculData.forfait || Infinity
      const plafondPourcentage = calculData.plafond_pourcentage || 100
      return Math.min(montantFacture * (plafondPourcentage / 100), forfait)
    } else if (this.slugValue === "warmtepomp") {
      // Pompe à chaleur - récupérer le type depuis un select si présent
      const typeSelect = this.element.querySelector('select')
      const typePompe = typeSelect?.value || "air_eau"
      return calculData.forfaits?.[typePompe] || 0
    } else {
      // Autres cas
      const forfait = calculData.forfait || 0
      const plafondPourcentage = calculData.plafond_pourcentage || 100
      return Math.min(montantFacture * (plafondPourcentage / 100), forfait)
    }
  }

  calculateForfait(calculData) {
    return calculData.forfait || calculData.montant || 0
  }

  calculatePourcentage(calculData) {
    if (!this.hasInputTarget) return 0

    const montantTravaux = parseFloat(this.inputTarget.value) || 0
    const pourcentage = calculData.pourcentage || 0
    const plafond = calculData.plafond || Infinity

    return Math.min((montantTravaux * pourcentage) / 100, plafond)
  }

  updateResult(amount) {
    if (this.hasResultTarget) {
      this.resultTarget.textContent = `${amount.toFixed(2)} €`
    }

    // Notifier le contrôleur parent
    this.element.dispatchEvent(new CustomEvent('flandre:card:updated', {
      bubbles: true,
      detail: {
        slug: this.slugValue,
        amount: amount
      }
    }))
  }

  getParentController() {
    // Trouver le contrôleur parent flandre-prime-calcul
    const parentElement = this.element.closest('[data-controller*="flandre-prime-calcul"]')
    if (parentElement) {
      return this.application.getControllerForElementAndIdentifier(parentElement, 'flandre-prime-calcul')
    }
    return null
  }

  restoreValues() {
    // Restaurer les valeurs depuis la base de données si disponibles
    // Cette méthode sera appelée par le contrôleur parent après la connexion

    if (this.hasInputTarget && this.inputTarget.dataset.savedValue) {
      this.inputTarget.value = this.inputTarget.dataset.savedValue
      this.calculate()
    }
  }

  // Action déclenchée par les inputs
  onInputChange() {
    this.calculate()
  }

  // Action déclenchée par les selects
  onSelectChange() {
    this.calculate()
  }
}
