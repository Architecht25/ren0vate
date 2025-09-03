// Contrôleur pour le calculateur Rénopack Wallonie
// Gère l'éligibilité, le calcul de capacité d'emprunt et les simulations

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "age", "revenus", "logementAge", "superficie", "montantTravaux",
    "resultEligibilite", "resultCapacite", "resultMensualite",
    "eligibiliteSection", "simulationSection", "resultSection",
    "detailsEligibilite", "detailsSimulation"
  ]

  static values = {
    seuilRevenus: { type: Number, default: 114400 }, // Seuil maximum RIG
    tauxInteret: { type: Number, default: 0 }, // Prêt à 0%
    dureeMaxMois: { type: Number, default: 300 } // 25 ans maximum
  }

  connect() {
    console.log("🏦 Contrôleur Rénopack Wallonie connecté")
    this.hideAllSections()
  }

  // Vérification de l'éligibilité
  checkEligibility() {
    const age = parseInt(this.ageTarget.value) || 0
    const revenus = parseFloat(this.revenusTarget.value) || 0
    const logementAge = parseInt(this.logementAgeTarget.value) || 0

    if (!age || !revenus || !logementAge) {
      this.hideAllSections()
      return
    }

    const criteres = this.evaluateEligibilityCriteria(age, revenus, logementAge)
    this.displayEligibilityResult(criteres)

    if (criteres.eligible) {
      this.showSimulationSection()
    } else {
      this.hideSimulationSection()
    }
  }

  evaluateEligibilityCriteria(age, revenus, logementAge) {
    const criteres = {
      age: age >= 18,
      ageRemboursement: age <= 60, // Pour être remboursé avant 86 ans avec 25 ans max
      revenus: revenus <= this.seuilRevenusValue,
      logementAge: logementAge >= 15,
      eligible: false
    }

    criteres.eligible = criteres.age && criteres.ageRemboursement &&
                       criteres.revenus && criteres.logementAge

    return criteres
  }

  displayEligibilityResult(criteres) {
    if (criteres.eligible) {
      this.resultEligibiliteTarget.innerHTML = `
        <div class="alert alert-success mb-0">
          <i class="bi bi-check-circle me-2"></i>
          <strong>Vous êtes éligible au Rénopack !</strong>
        </div>
      `
      this.detailsEligibiliteTarget.innerHTML = this.getEligibilityDetails(criteres, true)
    } else {
      this.resultEligibiliteTarget.innerHTML = `
        <div class="alert alert-warning mb-0">
          <i class="bi bi-exclamation-triangle me-2"></i>
          <strong>Critères d'éligibilité non remplis</strong>
        </div>
      `
      this.detailsEligibiliteTarget.innerHTML = this.getEligibilityDetails(criteres, false)
    }

    this.eligibiliteSectionTarget.classList.remove('d-none')
  }

  getEligibilityDetails(criteres, eligible) {
    const getStatusIcon = (condition) => condition ?
      '<i class="bi bi-check-circle text-success"></i>' :
      '<i class="bi bi-x-circle text-danger"></i>'

    return `
      <div class="mt-2">
        <h6 class="mb-1 small">Critères :</h6>
        <div class="small">
          <div class="d-flex align-items-center mb-1">
            ${getStatusIcon(criteres.age)}
            <span class="ms-1" style="font-size: 0.7rem;">Âge ≥18 ans</span>
          </div>
          <div class="d-flex align-items-center mb-1">
            ${getStatusIcon(criteres.ageRemboursement)}
            <span class="ms-1" style="font-size: 0.7rem;">Remb. <86 ans</span>
          </div>
          <div class="d-flex align-items-center mb-1">
            ${getStatusIcon(criteres.revenus)}
            <span class="ms-1" style="font-size: 0.7rem;">RIG <114k€</span>
          </div>
          <div class="d-flex align-items-center mb-1">
            ${getStatusIcon(criteres.logementAge)}
            <span class="ms-1" style="font-size: 0.7rem;">Logement >15 ans</span>
          </div>
        </div>
      </div>
    `
  }

  // Simulation du prêt
  calculateLoan() {
    const montantTravaux = parseFloat(this.montantTravauxTarget.value) || 0
    const revenus = parseFloat(this.revenusTarget.value) || 0

    if (!montantTravaux || !revenus) {
      this.hideResultSection()
      return
    }

    // Vérifications des limites Rénopack
    if (montantTravaux < 1000) {
      this.showError("Le montant minimum des travaux est de 1 000 €")
      return
    }

    if (montantTravaux > 60000) {
      this.showError("Le montant maximum du prêt Rénopack est de 60 000 €")
      return
    }

    const simulation = this.performLoanSimulation(montantTravaux, revenus)
    this.displaySimulationResult(simulation)
  }

  performLoanSimulation(montantTravaux, revenus) {
    // Capacité de remboursement : environ 30% des revenus
    const capaciteRemboursementMensuelle = (revenus * 0.30) / 12

    // Calcul des mensualités selon différentes durées
    const durees = [5, 10, 15, 20, 25] // en années
    const simulations = durees.map(dureeAnnees => {
      const dureeMois = dureeAnnees * 12
      const mensualite = montantTravaux / dureeMois // Taux 0%

      return {
        dureeAnnees,
        dureeMois,
        mensualite,
        faisable: mensualite <= capaciteRemboursementMensuelle
      }
    })

    // Trouver la durée optimale
    const dureeOptimale = simulations.find(sim => sim.faisable) || simulations[simulations.length - 1]

    return {
      montantTravaux,
      capaciteRemboursementMensuelle,
      simulations,
      dureeOptimale,
      totalInterets: 0 // Prêt à 0%
    }
  }

  displaySimulationResult(simulation) {
    const { montantTravaux, capaciteRemboursementMensuelle, dureeOptimale } = simulation

    this.resultCapaciteTarget.innerHTML = `
      <strong>${capaciteRemboursementMensuelle.toFixed(0)} € / mois</strong>
    `

    this.resultMensualiteTarget.innerHTML = `
      <strong>${dureeOptimale.mensualite.toFixed(0)} € / mois</strong>
      <small class="text-muted d-block">sur ${dureeOptimale.dureeAnnees} ans</small>
    `

    // Détails de la simulation
    this.detailsSimulationTarget.innerHTML = this.getSimulationDetails(simulation)

    this.resultSectionTarget.classList.remove('d-none')
  }

  getSimulationDetails(simulation) {
    const { simulations, dureeOptimale } = simulation

    let html = `
      <div class="mt-2">
        <h6 class="mb-1 small">Options :</h6>
        <div class="table-responsive">
          <table class="table table-sm small">
            <thead>
              <tr style="font-size: 0.7rem;">
                <th>Durée</th>
                <th>€/mois</th>
                <th>OK</th>
              </tr>
            </thead>
            <tbody>
    `

    simulations.slice(0, 3).forEach(sim => { // Limiter à 3 lignes pour l'espace
      const statusClass = sim.faisable ? 'table-success' : 'table-warning'
      const statusIcon = sim.faisable ?
        '<i class="bi bi-check-circle text-success"></i>' :
        '<i class="bi bi-exclamation-triangle text-warning"></i>'

      html += `
        <tr class="${statusClass}" style="font-size: 0.7rem;">
          <td>${sim.dureeAnnees}ans</td>
          <td>${sim.mensualite.toFixed(0)}€</td>
          <td>${statusIcon}</td>
        </tr>
      `
    })

    html += `
            </tbody>
          </table>
        </div>
        <div class="alert alert-info small mt-1 p-1">
          <i class="bi bi-info-circle me-1"></i>
          <strong style="font-size: 0.7rem;">${dureeOptimale.dureeAnnees} ans</strong>
          <span style="font-size: 0.65rem;">(${dureeOptimale.mensualite.toFixed(0)}€/mois)</span>
        </div>
      </div>
    `

    return html
  }

  showError(message) {
    this.resultSectionTarget.innerHTML = `
      <div class="alert alert-danger">
        <i class="bi bi-exclamation-triangle me-2"></i>
        ${message}
      </div>
    `
    this.resultSectionTarget.classList.remove('d-none')
  }

  // Gestion de l'affichage des sections
  hideAllSections() {
    this.eligibiliteSectionTarget.classList.add('d-none')
    this.simulationSectionTarget.classList.add('d-none')
    this.resultSectionTarget.classList.add('d-none')
  }

  showSimulationSection() {
    this.simulationSectionTarget.classList.remove('d-none')
  }

  hideSimulationSection() {
    this.simulationSectionTarget.classList.add('d-none')
    this.hideResultSection()
  }

  hideResultSection() {
    this.resultSectionTarget.classList.add('d-none')
  }

  // Action handlers
  eligibilityChanged() {
    this.checkEligibility()
  }

  loanChanged() {
    this.calculateLoan()
  }
}
