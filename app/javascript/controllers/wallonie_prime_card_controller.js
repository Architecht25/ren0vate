import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="wallonie-prime-card"
export default class extends Controller {
  static targets = []
  static values = { slug: String }

  connect() {
    this.setupTargets()
    this.calculate()
  }

  setupTargets() {
    // Créer dynamiquement les targets en fonction des inputs trouvés dans la carte
    const inputs = this.element.querySelectorAll('input, select')
    this.inputs = Array.from(inputs)

    // Créer les targets pour les résultats
    const resultElements = this.element.querySelectorAll('[data-wallonie-prime-card-target*="result"]')
    this.resultElements = Array.from(resultElements)

  }

  calculate() {
    if (!this.slugValue) {
      return
    }

    // Récupérer le controller parent pour accéder aux données
    const parentController = this.getParentController()
    if (!parentController) {
      return
    }

    const currentCategory = parentController.getCurrentCategory()
    const primesData = parentController.getPrimesData()

    // Vérifier si c'est une carte composite (globale)
    if (this.isCompositeCard()) {
      this.calculateComposite(currentCategory, primesData)
      return
    }

    // Trouver la prime correspondante
    const prime = primesData[this.slugValue]
    if (!prime) {
      return
    }

    // Calculer selon le type de calcul
    const calculData = prime.valeurs_par_categorie[currentCategory]
    if (!calculData) {
      return
    }

    let total = 0

    // Logique de calcul selon le type
    switch (calculData.type) {
      case 'montant_fixe':
        total = this.calculateMontantFixe(calculData)
        break
      case 'par_m2':
      case 'montant_m2':  // Support pour les deux formats
        total = this.calculateParM2(calculData)
        break
      case 'par_unite':
        total = this.calculateParUnite(calculData)
        break
      case 'pourcentage':
        total = this.calculatePourcentage(calculData)
        break
      default:
    }

    // Mettre à jour l'affichage
    this.updateResult(total)

    // Notifier le controller parent
    if (parentController.cardUpdated) {
      parentController.cardUpdated()
    }
  }

  calculateMontantFixe(calculData) {
    // Pour les montants fixes (audit par exemple)
    // Si input = "1" (Oui), on applique le montant, sinon 0
    const firstInput = this.inputs[0]
    if (!firstInput) return 0

    const inputValue = firstInput.value
    const isSelected = inputValue === "1" || inputValue === 1
    const montant = isSelected ? calculData.montant : 0


    return montant
  }

  calculateParM2(calculData) {
    const surfaceInput = this.inputs[0]
    if (!surfaceInput) return 0

    const surface = parseFloat(surfaceInput.value) || 0
    const prixParM2 = calculData.montant_m2 || calculData.montant_par_m2 || calculData.prix_par_m2 || calculData.montant || 0

    return surface * prixParM2
  }

  calculateParUnite(calculData) {
    const uniteInput = this.inputs[0]
    if (!uniteInput) return 0

    const unites = parseFloat(uniteInput.value) || 0
    const prixParUnite = calculData.montant_unitaire || calculData.montant_par_unite || calculData.prix_par_unite || calculData.montant || 0

    return unites * prixParUnite
  }

  calculatePourcentage(calculData) {
    const montantInput = this.inputs[0]
    if (!montantInput) return 0

    const montantTravaux = parseFloat(montantInput.value) || 0
    const pourcentage = calculData.pourcentage || 0
    const montantMax = calculData.montant_max || Infinity

    const calculResult = (montantTravaux * pourcentage) / 100
    return Math.min(calculResult, montantMax)
  }

  // Vérifie si c'est une carte composite (globale)
  isCompositeCard() {
    const compositeCards = [
      'wallonie_toiture_global',
      'wallonie_murs_global',
      'wallonie_sols_global',
      'wallonie_ventilation_global',
      'wallonie_chaudiere_global',
      'wallonie_amelioration_chauffage_global',
      'wallonie_eau_chaude_sanitaire_global'
    ]
    return compositeCards.includes(this.slugValue)
  }

  // Calcule les primes pour une carte composite
  calculateComposite(currentCategory, primesData) {
    let totalGlobal = 0

    // Définir les primes à calculer selon la carte
    const primesToCalculate = this.getCompositePrimes()

    primesToCalculate.forEach(compositeDefinition => {
      const { slug, inputSelector, resultSelector } = compositeDefinition
      const prime = primesData[slug]

      if (!prime) {
        return
      }

      const calculData = prime.valeurs_par_categorie[currentCategory]
      if (!calculData) {
        return
      }

      // Trouver l'input correspondant
      const input = this.element.querySelector(inputSelector)
      if (!input) {
        return
      }

      // Calculer le montant pour cette prime spécifique
      let montant = 0
      const inputValue = input.value

      switch (calculData.type) {
        case 'montant_fixe':
          // Pour les montants fixes (audit, primes ECS, etc.)
          // Si input = "1" (Oui), on applique le montant, sinon 0
          const isSelected = inputValue === "1" || inputValue === 1
          montant = isSelected ? calculData.montant : 0
          break
        case 'par_m2':
        case 'montant_m2':  // Support pour les deux formats
          // Pour les calculs par m² (isolation par exemple)
          // montant = surface_m2 * prix_par_m2
          const surface = parseFloat(inputValue) || 0
          const prixParM2 = calculData.montant_m2 || calculData.montant_par_m2 || calculData.prix_par_m2 || calculData.montant || 0
          montant = surface * prixParM2
          break
        case 'par_unite':
        case 'montant_par_unite':  // Support pour les deux formats
          // Pour les calculs par unité (fenêtres, radiateurs, etc.)
          // montant = nombre_unites * prix_par_unite
          const unites = parseFloat(inputValue) || 0
          const prixParUnite = calculData.montant_unitaire || calculData.montant_par_unite || calculData.prix_par_unite || calculData.montant || 0
          montant = unites * prixParUnite
          break
        case 'pourcentage':
          // Pour les calculs en pourcentage (du montant des travaux)
          const montantTravaux = parseFloat(inputValue) || 0
          const pourcentage = calculData.pourcentage || calculData.taux_pourcentage || 0
          const montantMax = calculData.montant_max || Infinity
          const calculResult = (montantTravaux * pourcentage) / 100
          montant = Math.min(calculResult, montantMax)
          break
        default:
      }

      // Mettre à jour l'affichage de ce résultat spécifique
      const resultElement = this.element.querySelector(resultSelector)
      if (resultElement) {
        resultElement.textContent = `${montant.toLocaleString('fr-FR')} €`
      } else {
      }

      totalGlobal += montant
    })

    // Mettre à jour le total global de la carte
    this.updateGlobalTotal(totalGlobal)

    // Notifier le controller parent
    const parentController = this.getParentController()
    if (parentController && parentController.cardUpdated) {
      parentController.cardUpdated()
    }
  }

  // Définit les primes composites selon le type de carte
  getCompositePrimes() {
    switch (this.slugValue) {
      case 'wallonie_toiture_global':
        return [
          { slug: 'wallonie_toiture_remplacement_couverture', inputSelector: '[data-wallonie-prime-card-target="inputCouverture"]', resultSelector: '[data-wallonie-prime-card-target="resultCouverture"]' },
          { slug: 'wallonie_toiture_appropriation_charpente', inputSelector: '[data-wallonie-prime-card-target="inputCharpente"]', resultSelector: '[data-wallonie-prime-card-target="resultCharpente"]' },
          { slug: 'wallonie_toiture_evacuation_eaux_pluviales', inputSelector: '[data-wallonie-prime-card-target="inputEvacuation"]', resultSelector: '[data-wallonie-prime-card-target="resultEvacuation"]' },
          { slug: 'wallonie_toiture_isolation_thermique', inputSelector: '[data-wallonie-prime-card-target="inputIsolationThermique"]', resultSelector: '[data-wallonie-prime-card-target="resultIsolationThermique"]' },
          { slug: 'wallonie_toiture_isolation_biosource', inputSelector: '[data-wallonie-prime-card-target="inputIsolationBiosource"]', resultSelector: '[data-wallonie-prime-card-target="resultIsolationBiosource"]' }
        ]

      case 'wallonie_murs_global':
        return [
          { slug: 'wallonie_assechement_murs_infiltration', inputSelector: '[data-wallonie-prime-card-target="inputInfiltration"]', resultSelector: '[data-wallonie-prime-card-target="resultInfiltration"]' },
          { slug: 'wallonie_assechement_murs_humidite', inputSelector: '[data-wallonie-prime-card-target="inputHumidite"]', resultSelector: '[data-wallonie-prime-card-target="resultHumidite"]' },
          { slug: 'wallonie_renforcement_murs', inputSelector: '[data-wallonie-prime-card-target="inputRenforcement"]', resultSelector: '[data-wallonie-prime-card-target="resultRenforcement"]' },
          { slug: 'wallonie_elimination_merule', inputSelector: '[data-wallonie-prime-card-target="inputMerule"]', resultSelector: '[data-wallonie-prime-card-target="resultMerule"]' },
          { slug: 'wallonie_elimination_radon', inputSelector: '[data-wallonie-prime-card-target="inputRadon"]', resultSelector: '[data-wallonie-prime-card-target="resultRadon"]' },
          { slug: 'wallonie_isolation_murs', inputSelector: '[data-wallonie-prime-card-target="inputIsolationThermique"]', resultSelector: '[data-wallonie-prime-card-target="resultIsolationThermique"]' },
          { slug: 'wallonie_isolation_murs_biosource', inputSelector: '[data-wallonie-prime-card-target="inputIsolationBiosource"]', resultSelector: '[data-wallonie-prime-card-target="resultIsolationBiosource"]' }
        ]

      case 'wallonie_sols_global':
        return [
          { slug: 'wallonie_isolation_sols', inputSelector: '[data-wallonie-prime-card-target="inputIsolationSols"]', resultSelector: '[data-wallonie-prime-card-target="resultIsolationSols"]' },
          { slug: 'wallonie_isolation_sols_biosource', inputSelector: '[data-wallonie-prime-card-target="inputIsolationBiosource"]', resultSelector: '[data-wallonie-prime-card-target="resultIsolationBiosource"]' },
          { slug: 'wallonie_remplacement_supports_circulation', inputSelector: '[data-wallonie-prime-card-target="inputSupports"]', resultSelector: '[data-wallonie-prime-card-target="resultSupports"]' },
          { slug: 'wallonie_isolation_finition_planchers', inputSelector: '[data-wallonie-prime-card-target="inputFinitionPlanchers"]', resultSelector: '[data-wallonie-prime-card-target="resultFinitionPlanchers"]' }
        ]

      case 'wallonie_ventilation_global':
        return [
          { slug: 'wallonie_vmc_simple', inputSelector: '[data-wallonie-prime-card-target="inputVmcSimpleComplete"]', resultSelector: '[data-wallonie-prime-card-target="resultVmcSimpleComplete"]' },
          { slug: 'wallonie_vmc_double', inputSelector: '[data-wallonie-prime-card-target="inputVmcDoubleComplete"]', resultSelector: '[data-wallonie-prime-card-target="resultVmcDoubleComplete"]' },
          { slug: 'wallonie_vmc_simple_partielle', inputSelector: '[data-wallonie-prime-card-target="inputVmcSimplePartielle"]', resultSelector: '[data-wallonie-prime-card-target="resultVmcSimplePartielle"]' },
          { slug: 'wallonie_vmc_double_partielle', inputSelector: '[data-wallonie-prime-card-target="inputVmcDoublePartielle"]', resultSelector: '[data-wallonie-prime-card-target="resultVmcDoublePartielle"]' }
        ]

      case 'wallonie_chaudiere_global':
        return [
          { slug: 'wallonie_pac_eau_chaude', inputSelector: '[data-wallonie-prime-card-target="inputPacEauChaude"]', resultSelector: '[data-wallonie-prime-card-target="resultPacEauChaude"]' },
          { slug: 'wallonie_pac_chauffage', inputSelector: '[data-wallonie-prime-card-target="inputPacChauffage"]', resultSelector: '[data-wallonie-prime-card-target="resultPacChauffage"]' },
          { slug: 'wallonie_chaudiere_biomasse', inputSelector: '[data-wallonie-prime-card-target="inputChaudiereBiomasse"]', resultSelector: '[data-wallonie-prime-card-target="resultChaudiereBiomasse"]' },
          { slug: 'wallonie_poele_biomasse', inputSelector: '[data-wallonie-prime-card-target="inputPoeleBiomasse"]', resultSelector: '[data-wallonie-prime-card-target="resultPoeleBiomasse"]' },
          { slug: 'wallonie_chauffe_eau_solaire', inputSelector: '[data-wallonie-prime-card-target="inputChauffeEauSolaire"]', resultSelector: '[data-wallonie-prime-card-target="resultChauffeEauSolaire"]' }
        ]

      case 'wallonie_amelioration_chauffage_global':
        return [
          { slug: 'wallonie_chauffage_isol_conduites', inputSelector: '[data-wallonie-prime-card-target="inputIsolationConduites"]', resultSelector: '[data-wallonie-prime-card-target="resultIsolationConduites"]' },
          { slug: 'wallonie_chauffage_isol_ballon_500', inputSelector: '[data-wallonie-prime-card-target="inputIsolationBallon500"]', resultSelector: '[data-wallonie-prime-card-target="resultIsolationBallon500"]' },
          { slug: 'wallonie_chauffage_isol_ballon_sup', inputSelector: '[data-wallonie-prime-card-target="inputIsolationBallonPlus500"]', resultSelector: '[data-wallonie-prime-card-target="resultIsolationBallonPlus500"]' },
          { slug: 'wallonie_chauffage_circ_3logt', inputSelector: '[data-wallonie-prime-card-target="inputCirculateurMax3Logements"]', resultSelector: '[data-wallonie-prime-card-target="resultCirculateurMax3Logements"]' },
          { slug: 'wallonie_chauffage_circ_4logt', inputSelector: '[data-wallonie-prime-card-target="inputCirculateurMin4Logements"]', resultSelector: '[data-wallonie-prime-card-target="resultCirculateurMin4Logements"]' },
          { slug: 'wallonie_chauffage_ballon_500', inputSelector: '[data-wallonie-prime-card-target="inputRemplacementBallon500"]', resultSelector: '[data-wallonie-prime-card-target="resultRemplacementBallon500"]' },
          { slug: 'wallonie_chauffage_ballon_sup', inputSelector: '[data-wallonie-prime-card-target="inputRemplacementBallonPlus500"]', resultSelector: '[data-wallonie-prime-card-target="resultRemplacementBallonPlus500"]' },
          { slug: 'wallonie_chauffage_vannes_base', inputSelector: '[data-wallonie-prime-card-target="inputMin5VannesThermostatiques"]', resultSelector: '[data-wallonie-prime-card-target="resultMin5VannesThermostatiques"]' },
          { slug: 'wallonie_chauffage_vannes_sup', inputSelector: '[data-wallonie-prime-card-target="inputVannesSupplementaires"]', resultSelector: '[data-wallonie-prime-card-target="resultVannesSupplementaires"]' },
          { slug: 'wallonie_chauffage_thermostat', inputSelector: '[data-wallonie-prime-card-target="inputThermostatAmbiance"]', resultSelector: '[data-wallonie-prime-card-target="resultThermostatAmbiance"]' }
        ]

      case 'wallonie_eau_chaude_sanitaire_global':
        return [
          { slug: 'wallonie_ecs_ballon_500', inputSelector: '[data-wallonie-prime-card-target="inputRemplacementBallon500"]', resultSelector: '[data-wallonie-prime-card-target="resultRemplacementBallon500"]' },
          { slug: 'wallonie_ecs_ballon_sup', inputSelector: '[data-wallonie-prime-card-target="inputRemplacementBallonSup"]', resultSelector: '[data-wallonie-prime-card-target="resultRemplacementBallonSup"]' },
          { slug: 'wallonie_ecs_conduites_coll', inputSelector: '[data-wallonie-prime-card-target="inputIsolationConduites"]', resultSelector: '[data-wallonie-prime-card-target="resultIsolationConduites"]' },
          { slug: 'wallonie_ecs_echangeur', inputSelector: '[data-wallonie-prime-card-target="inputEchangeurPlaques"]', resultSelector: '[data-wallonie-prime-card-target="resultEchangeurPlaques"]' },
          { slug: 'wallonie_ecs_isol_ballon_500', inputSelector: '[data-wallonie-prime-card-target="inputIsolationBallon500"]', resultSelector: '[data-wallonie-prime-card-target="resultIsolationBallon500"]' },
          { slug: 'wallonie_ecs_isol_ballon_sup', inputSelector: '[data-wallonie-prime-card-target="inputIsolationBallonSup"]', resultSelector: '[data-wallonie-prime-card-target="resultIsolationBallonSup"]' }
        ]

      // Ajouter les autres cartes globales au besoin
      default:
        return []
    }
  }

  // Met à jour le total global de la carte composite
  updateGlobalTotal(totalGlobal) {
    const globalTargetName = this.getGlobalTargetName()
    const globalTarget = this.element.querySelector(`[data-wallonie-prime-card-target="${globalTargetName}"]`)

    if (globalTarget) {
      globalTarget.textContent = `${totalGlobal.toLocaleString('fr-FR')} €`
    }
  }

  // Détermine le nom du target pour le total global
  getGlobalTargetName() {
    switch (this.slugValue) {
      case 'wallonie_toiture_global': return 'totalToiture'
      case 'wallonie_murs_global': return 'totalMurs'
      case 'wallonie_sols_global': return 'totalSols'
      case 'wallonie_ventilation_global': return 'totalVentilation'
      case 'wallonie_chaudiere_global': return 'totalChaudiere'
      case 'wallonie_amelioration_chauffage_global': return 'totalAmeliorationChauffage'
      case 'wallonie_eau_chaude_sanitaire_global': return 'totalEauChaudeSanitaire'
      default: return 'total'
    }
  }

  updateResult(montant) {
    // Mettre à jour tous les éléments de résultat de cette carte
    this.resultElements.forEach(element => {
      element.textContent = `${montant.toLocaleString('fr-FR', {
        minimumFractionDigits: 0,
        maximumFractionDigits: 0
      })} €`
    })
  }

  // Méthode pour recalculer (appelée depuis le controller parent)
  recalculate() {
    this.calculate()
  }

  getParentController() {
    // Trouver le controller parent wallonie-prime-calcul
    let parent = this.element.parentElement
    while (parent) {
      if (parent.hasAttribute('data-controller') &&
          parent.getAttribute('data-controller').includes('wallonie-prime-calcul')) {
        return this.application.getControllerForElementAndIdentifier(parent, 'wallonie-prime-calcul')
      }
      parent = parent.parentElement
    }
    return null
  }

  // Actions pour les différents types d'inputs
  calculateAudit() { this.calculate() }
  calculateToiture() { this.calculate() }
  calculateMurs() { this.calculate() }
  calculateSols() { this.calculate() }
  calculateChauffage() { this.calculate() }
  calculateEauSanitaire() { this.calculate() }
  calculateVentilation() { this.calculate() }
  calculateFenetres() { this.calculate() }
  calculateElectricite() { this.calculate() }
  calculateRenouvelables() { this.calculate() }
  calculateChaudiere() { this.calculate() }
  calculateAmeliorationChauffage() { this.calculate() }
  calculateEauChaudeSanitaire() { this.calculate() }
  calculateMenuiseriesVitrages() { this.calculate() }
  calculateInstallationElectrique() { this.calculate() }
  calculateInstallationGaz() { this.calculate() }
  calculateMenuiseries() { this.calculate() }
  calculateGaz() { this.calculate() }
}
