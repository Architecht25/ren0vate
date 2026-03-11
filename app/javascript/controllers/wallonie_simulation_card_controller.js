import { Controller } from "@hotwired/stimulus"

// Contrôleur de carte dédié aux simulations Wallonie post-login
// Séparé du contrôleur home page pour éviter les conflits
export default class extends Controller {
  static targets = [
    "total", "status", "input", "selectEtude", "selectType", "description",
    // Targets pour les résultats individuels des cartes complexes
    // Toiture
    "resultCouverture", "resultCharpente", "resultEvacuation", "resultIsolationThermique", "resultIsolationBiosource",
    // Murs
    "resultInfiltration", "resultHumidite", "resultRenforcement", "resultMerule", "resultRadon", "resultIsolationThermique", "resultIsolationBiosource",
    // Sols
    "resultIsolationSols", "resultIsolationBiosource", "resultSupports", "resultFinitionPlanchers",
    // Chaudière et PAC
    "resultPacEauChaude", "resultPacChauffage", "resultChaudiereBiomasse", "resultPoeleBiomasse", "resultChauffeEauSolaire",
    // Ventilation
    "resultVmcSimpleComplete", "resultVmcDoubleComplete", "resultVmcSimplePartielle", "resultVmcDoublePartielle",
    // Amélioration chauffage
    "resultIsolationConduites", "resultIsolationBallon500", "resultIsolationBallonPlus500", "resultCirculateurMax3Logements", "resultCirculateurMin4Logements",
    "resultRemplacementBallon500", "resultRemplacementBallonPlus500", "resultMin5VannesThermostatiques", "resultVannesSupplementaires", "resultThermostatAmbiance",
    // Eau chaude sanitaire
    "resultRemplacementBallonSup", "resultEchangeurPlaques", "resultIsolationBallonSup"
  ]
  static values = { slug: String }

  connect() {

    // Initialiser à 0€ en attendant les calculs backend
    this.updateResult(0)

    // Écouter les événements de mise à jour depuis le contrôleur parent
    document.addEventListener('wallonie:prime-updated', this.handlePrimeUpdate.bind(this))
  }

  disconnect() {
    document.removeEventListener('wallonie:prime-updated', this.handlePrimeUpdate.bind(this))
  }

  handlePrimeUpdate(event) {

    const allPrimes = event.detail || {}
    let cardTotal = 0

    // Pour les cartes simples (audit par exemple)
    if (allPrimes[this.slugValue]) {
      const primeAmount = parseFloat(allPrimes[this.slugValue]) || 0
      cardTotal = primeAmount
      this.updateResult(cardTotal)
      return
    }

    // Mapping des slugs vers les targets de résultats
    const slugToTargetMap = {
      // Toiture
      'wallonie_toiture_remplacement_couverture': 'resultCouverture',
      'wallonie_toiture_appropriation_charpente': 'resultCharpente',
      'wallonie_toiture_evacuation_eaux_pluviales': 'resultEvacuation',
      'wallonie_toiture_isolation_thermique': 'resultIsolationThermique',
      'wallonie_toiture_isolation_biosource': 'resultIsolationBiosource',
      // Murs
      'wallonie_assechement_murs_infiltration': 'resultInfiltration',
      'wallonie_assechement_murs_humidite': 'resultHumidite',
      'wallonie_renforcement_murs': 'resultRenforcement',
      'wallonie_elimination_merule': 'resultMerule',
      'wallonie_elimination_radon': 'resultRadon',
      'wallonie_murs_isolation_thermique': 'resultIsolationThermique',
      'wallonie_murs_isolation_biosource': 'resultIsolationBiosource',
      // Sols
      'wallonie_isolation_sols': 'resultIsolationSols',
      'wallonie_sols_isolation_biosource': 'resultIsolationBiosource',
      'wallonie_remplacement_supports_circulation': 'resultSupports',
      'wallonie_isolation_finition_planchers': 'resultFinitionPlanchers',
      // Chaudière et PAC
      'wallonie_pac_eau_chaude': 'resultPacEauChaude',
      'wallonie_pac_chauffage': 'resultPacChauffage',
      'wallonie_chaudiere_biomasse': 'resultChaudiereBiomasse',
      'wallonie_poele_biomasse': 'resultPoeleBiomasse',
      'wallonie_chauffe_eau_solaire': 'resultChauffeEauSolaire',
      // Ventilation
      'wallonie_vmc_simple': 'resultVmcSimpleComplete',
      'wallonie_vmc_double': 'resultVmcDoubleComplete',
      'wallonie_vmc_simple_partielle': 'resultVmcSimplePartielle',
      'wallonie_vmc_double_partielle': 'resultVmcDoublePartielle',
      // Amélioration chauffage
      'wallonie_chauffage_isol_conduites': 'resultIsolationConduites',
      'wallonie_chauffage_isol_ballon_500': 'resultIsolationBallon500',
      'wallonie_chauffage_isol_ballon_sup': 'resultIsolationBallonPlus500',
      'wallonie_chauffage_circ_3logt': 'resultCirculateurMax3Logements',
      'wallonie_chauffage_circ_4logt': 'resultCirculateurMin4Logements',
      'wallonie_chauffage_ballon_500': 'resultRemplacementBallon500',
      'wallonie_chauffage_ballon_sup': 'resultRemplacementBallonPlus500',
      'wallonie_chauffage_vannes_base': 'resultMin5VannesThermostatiques',
      'wallonie_chauffage_vannes_sup': 'resultVannesSupplementaires',
      'wallonie_chauffage_thermostat': 'resultThermostatAmbiance',
      // Eau chaude sanitaire
      'wallonie_ecs_ballon_sup': 'resultRemplacementBallonSup',
      'wallonie_ecs_echangeur': 'resultEchangeurPlaques',
      'wallonie_ecs_isol_ballon_sup': 'resultIsolationBallonSup'
    }

    // Mapping des cartes vers leurs sous-primes
    const cardToPrimesMap = {
      'wallonie_toiture_global': [
        'wallonie_toiture_remplacement_couverture',
        'wallonie_toiture_appropriation_charpente',
        'wallonie_toiture_evacuation_eaux_pluviales',
        'wallonie_toiture_isolation_thermique',
        'wallonie_toiture_isolation_biosource'
      ],
      'wallonie_murs_global': [
        'wallonie_assechement_murs_infiltration',
        'wallonie_assechement_murs_humidite',
        'wallonie_renforcement_murs',
        'wallonie_elimination_merule',
        'wallonie_elimination_radon',
        'wallonie_murs_isolation_thermique',
        'wallonie_murs_isolation_biosource'
      ],
      'wallonie_sols_global': [
        'wallonie_isolation_sols',
        'wallonie_sols_isolation_biosource',
        'wallonie_remplacement_supports_circulation',
        'wallonie_isolation_finition_planchers'
      ],
      'wallonie_chaudiere_global': [
        'wallonie_pac_eau_chaude',
        'wallonie_pac_chauffage',
        'wallonie_chaudiere_biomasse',
        'wallonie_poele_biomasse',
        'wallonie_chauffe_eau_solaire'
      ],
      'wallonie_ventilation_global': [
        'wallonie_vmc_simple',
        'wallonie_vmc_double',
        'wallonie_vmc_simple_partielle',
        'wallonie_vmc_double_partielle'
      ],
      'wallonie_amelioration_chauffage_global': [
        'wallonie_chauffage_isol_conduites',
        'wallonie_chauffage_isol_ballon_500',
        'wallonie_chauffage_isol_ballon_sup',
        'wallonie_chauffage_circ_3logt',
        'wallonie_chauffage_circ_4logt',
        'wallonie_chauffage_ballon_500',
        'wallonie_chauffage_ballon_sup',
        'wallonie_chauffage_vannes_base',
        'wallonie_chauffage_vannes_sup',
        'wallonie_chauffage_thermostat'
      ],
      'wallonie_eau_chaude_sanitaire_global': [
        'wallonie_chauffage_ballon_500', // partagé avec amélioration chauffage
        'wallonie_ecs_ballon_sup',
        'wallonie_chauffage_isol_conduites', // partagé avec amélioration chauffage
        'wallonie_ecs_echangeur',
        'wallonie_chauffage_isol_ballon_500', // partagé avec amélioration chauffage
        'wallonie_ecs_isol_ballon_sup'
      ]
    }

    // Pour les cartes complexes, utiliser le mapping
    const expectedPrimes = cardToPrimesMap[this.slugValue] || []

    expectedPrimes.forEach(primeSlug => {

      if (allPrimes[primeSlug]) {
        const primeAmount = parseFloat(allPrimes[primeSlug]) || 0
        cardTotal += primeAmount

        // Mettre à jour le span individuel si le target existe
        const targetName = slugToTargetMap[primeSlug]

        if (targetName) {
          try {
            // Tenter d'accéder au target - cela lèvera une erreur s'il n'existe pas
            const targetElement = this[`${targetName}Target`]
            targetElement.textContent = `${primeAmount} €`
          } catch (error) {
          }
        } else {
        }
      }
    })

    // Mettre à jour le total de la carte
    this.updateResult(cardTotal)
  }

  calculate() {

    if (!this.slugValue) {
      return
    }

    // Déclencher la sauvegarde automatique du parent qui se chargera du calcul backend
    this.triggerAutoSave()
  }

  // Méthodes spécifiques pour chaque type de carte
  calculateToiture() {
    this.calculate()
  }

  calculateMurs() {
    this.calculate()
  }

  calculateSols() {
    this.calculate()
  }

  calculateAmeliorationChauffage() {
    this.calculate()
  }

  calculateEauChaudeSanitaire() {
    this.calculate()
  }

  calculateChaudiere() {
    this.calculate()
  }

  calculateVentilation() {
    this.calculate()
  }

  calculateMenuiseries() {
    this.calculate()
  }

  calculateGaz() {
    this.calculate()
  }

  calculateElectricite() {
    this.calculate()
  }

  triggerAutoSave() {
    // Déclencher un événement pour notifier le contrôleur parent
    const event = new CustomEvent('wallonie:card-changed', {
      detail: { slug: this.slugValue },
      bubbles: true
    })
    this.element.dispatchEvent(event)
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
    if (this.slugValue.includes('isolation_toiture')) {
      // Logique spéciale pour isolation toiture
      const surface = parseFloat(inputs.surface) || 0
      const montantParM2 = categoryData.montant_par_m2 || 0
      total = surface * montantParM2
    } else if (this.slugValue.includes('chauffage')) {
      // Logique pour système de chauffage
      const typeInstallation = inputs.type_installation || 'standard'
      const puissance = parseFloat(inputs.puissance) || 0

      const montantBase = categoryData.montant_base || 0
      const montantParKw = categoryData.montant_par_kw || 0

      total = montantBase + (puissance * montantParKw)
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
    // Chercher le contrôleur parent wallonie-simulation pour les simulations
    let parent = this.element.parentElement
    while (parent) {
      if (parent.hasAttribute('data-controller') &&
          parent.getAttribute('data-controller').includes('wallonie-simulation')) {
        return this.application.getControllerForElementAndIdentifier(parent, 'wallonie-simulation')
      }
      parent = parent.parentElement
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
