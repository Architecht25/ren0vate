import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "result", "typeMur"]
  static values = { slug: String }

  connect() {

    // Écouter les changements de catégorie
    this.element.addEventListener('flandre:category:changed', this.recalculate.bind(this))

    // Écouter les événements de recalcul forcé
    this.element.addEventListener('flandre:force:recalculate', this.forceRecalculate.bind(this))

    // Mettre à jour le placeholder initial avec délai pour attendre les données
    setTimeout(() => {
      this.updatePlaceholder()
    }, 150)

    // Calculer le montant initial avec un délai pour laisser le parent se charger
    setTimeout(() => {
      this.calculate()
    }, 100)
  }

  disconnect() {
    this.element.removeEventListener('flandre:category:changed', this.recalculate.bind(this))
    this.element.removeEventListener('flandre:force:recalculate', this.forceRecalculate.bind(this))
  }

  forceRecalculate() {
    this.calculate()
  }

  recalculate() {
    // Attendre un court instant pour que les données de catégorie soient mises à jour
    setTimeout(() => {
      this.updatePlaceholder()
      this.calculate()
    }, 50)
  }

  updatePlaceholder() {
    if (!this.hasInputTarget) return

    const parentController = this.getParentController()
    if (!parentController) return

    const currentCategory = parentController.getCurrentCategory()
    const primesData = parentController.getPrimesData()
    const prime = primesData[this.slugValue]


    if (prime && prime.placeholder) {
      const placeholderTexte = prime.placeholder[currentCategory]

      // Si un placeholder spécifique existe pour cette catégorie, on l'applique
      if (placeholderTexte && placeholderTexte.trim() !== '') {
        this.inputTarget.placeholder = placeholderTexte
      } else {
        // Fallback plus intelligent basé sur la catégorie
        const fallbackPlaceholder = ["4", "3"].includes(currentCategory)
          ? "Montant total de la facture (€)"
          : "Surface en m²"
        this.inputTarget.placeholder = fallbackPlaceholder
      }
    } else {
      // Fallback par défaut
      this.inputTarget.placeholder = ["4", "3"].includes(currentCategory)
        ? "Montant total de la facture (€)"
        : "Surface en m²"
    }
  }

  calculate() {
    if (!this.slugValue) {
      return
    }

    // Mettre à jour le placeholder à chaque calcul
    this.updatePlaceholder()

    // Récupérer le contrôleur parent pour accéder aux données
    const parentController = this.getParentController()
    if (!parentController) {
      return
    }


    // Vérifier que les données de primes sont disponibles
    const primesData = parentController.getPrimesData()
    if (!primesData || Object.keys(primesData).length === 0) {
      setTimeout(() => this.calculate(), 500)
      return
    }


    const currentCategory = parentController.getCurrentCategory()

    // DEBUG: Affichons la structure exacte des données de primes

    // Trouver la prime correspondante
    const prime = primesData[this.slugValue]
    if (!prime) {
      this.updateResult(0)
      return
    }


    // Extraire le numéro de catégorie (ex: 'flandre_cat2' -> '2')
    const categoryNumber = currentCategory.replace('flandre_cat', '')

    // Calculer selon le type de calcul
    const calculData = prime.valeurs_par_categorie?.[categoryNumber]
    if (!calculData) {
      // Vérifier si la prime existe pour d'autres catégories
      const availableCategories = Object.keys(prime.valeurs_par_categorie || {})
      if (availableCategories.length > 0) {
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
      case 'pourcentage_et_plafond':
        total = this.calculatePourcentageEtPlafond(calculData)
        break
      case 'montant':
        total = this.calculateMontant(calculData)
        break
      case 'prime_conditionnelle':
        total = this.calculatePrimeConditionnelle(calculData)
        break
      default:
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

    // Si pas de surface, retourner 0
    if (surface === 0) {
      return 0
    }

    // Récupérer le type de mur sélectionné
    let typeMur = null
    if (this.hasTypeMurTarget) {
      typeMur = this.typeMurTarget.value
    }

    // Si aucun type sélectionné, retourner 0
    if (!typeMur || typeMur === "") {
      return 0
    }

    const montantParM2 = calculData.montants_m2?.[typeMur] || 0
    const surfaceMax = calculData.surface_max || Infinity
    const surfaceLimitee = Math.min(surface, surfaceMax)


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
      const typePompe = typeSelect?.value

      // Retourner 0 si aucun type n'est sélectionné
      if (!typePompe || typePompe === "") {
        return 0
      }

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

    // Récupérer le contrôleur parent pour appliquer les plafonds
    const parentController = this.getParentController()
    let finalAmount = amount

    if (parentController) {
      const result = parentController.calculateMontantAvecPlafond(this.slugValue, amount)
      finalAmount = result.montant

      if (finalAmount !== amount) {
      }
    }

    if (this.hasResultTarget) {
      this.resultTarget.textContent = `${finalAmount.toFixed(2)} €`
    } else {
    }

    // Notifier le contrôleur parent
    this.element.dispatchEvent(new CustomEvent('flandre:card:updated', {
      bubbles: true,
      detail: {
        slug: this.slugValue,
        amount: finalAmount
      }
    }))
  }

  getParentController() {
    // Trouver le contrôleur parent flandre-simulation en remontant dans le DOM
    let element = this.element.parentElement
    while (element) {
      // Chercher un élément avec data-controller qui contient exactement 'flandre-simulation'
      // mais pas 'flandre-simulation-card'
      const controllers = element.dataset.controller
      if (controllers && controllers.includes('flandre-simulation') && !controllers.includes('flandre-simulation-card')) {
        const controller = this.application.getControllerForElementAndIdentifier(element, 'flandre-simulation')
        return controller
      }
      element = element.parentElement
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

  // Action déclenchée par les inputs (via data-action dans le HTML)
  onInputChange() {

    // Recalculer immédiatement quand l'utilisateur change la valeur
    this.calculate()

    // Déclencher une sauvegarde via le controller parent avec debounce
    const parentController = this.getParentController()
    if (parentController) {
      // Utiliser un debounce pour éviter les sauvegardes trop fréquentes
      clearTimeout(this.saveTimeout)
      this.saveTimeout = setTimeout(() => {
        parentController.saveAndCalculateAll()
      }, 500)
    } else {
    }
  }

  // Action déclenchée par les selects
  onSelectChange() {
    this.calculate()
  }

  calculatePourcentageEtPlafond(calculData) {
    // Type: pourcentage avec plafond (ex: 50% du montant avec un plafond de 5750€)
    let inputValue = 0

    if (this.hasInputTarget) {
      inputValue = parseFloat(this.inputTarget.value) || 0
    }

    if (inputValue === 0) {
      return 0
    }

    const pourcentage = calculData.pourcentage || 0
    const plafond = calculData.plafond || 0

    const montantCalcule = (inputValue * pourcentage) / 100

    // Appliquer le plafond si défini
    return plafond > 0 ? Math.min(montantCalcule, plafond) : montantCalcule
  }

  calculateMontant(calculData) {
    // Type: montant fixe simple
    return calculData.forfait || calculData.valeur || 0
  }

  calculatePrimeConditionnelle(calculData) {
    // Type: prime conditionnelle - toujours 0 par défaut
    return 0
  }
}
