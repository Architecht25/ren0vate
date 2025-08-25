import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["eligibleAids", "improvementAids", "ineligibleAids", "results"]
  static values = {
    company: Object,
    aids: Array
  }

  connect() {
    console.log("Eligibility Checker controller connected")
    // Simuler des données d'entreprise pour le test
    this.companyValue = {
      denomination: "RenovaTech Solutions SPRL",
      numero_bce: "0833618097",
      statut: "ACTIF",
      code_nace: "71121",
      forme_juridique: "Société privée à responsabilité limitée",
      nombre_employes: 75, // Pour déclencher des améliorations potentielles
      date_creation: "2022-01-01", // Entreprise récente
      adresse: {
        code_postal: "1000" // Bruxelles
      }
    }
    this.loadAids()
  }

  async loadAids() {
    this.showLoading()
    try {
      const response = await fetch('/api/entreprises/bruxelles/aides')
      const aids = await response.json()

      this.aidsValue = aids
      console.log("Aides chargées:", aids.length)
      console.log("Première aide complète:", aids[0]) // DEBUG: voir la structure

      // Déclencher l'analyse dès qu'on a les aides et les données d'entreprise
      if (this.companyValue) {
        this.checkEligibility()
      }
    } catch (error) {
      console.error("Erreur lors du chargement des aides:", error)
    } finally {
      this.hideLoading()
    }
  }

  // Méthode publique pour démarrer l'analyse avec les données d'entreprise
  startAnalysis(companyData) {
    console.log("Starting eligibility analysis for:", companyData)
    this.companyValue = companyData

    if (this.aidsValue && this.aidsValue.length > 0) {
      this.showLoading()
      // Petit délai pour l'effet visuel
      setTimeout(() => {
        this.checkEligibility()
        this.hideLoading()
      }, 1000)
    } else {
      console.warn("Aides pas encore chargées, recharger...")
      this.loadAidsAndCheck(companyData)
    }
  }

  async loadAidsAndCheck(companyData) {
    this.showLoading()
    try {
      const response = await fetch('/api/entreprises/bruxelles/aides')
      const aids = await response.json()
      this.aidsValue = aids
      this.companyValue = companyData
      this.checkEligibility()
    } catch (error) {
      console.error("Erreur lors du chargement des aides:", error)
    } finally {
      this.hideLoading()
    }
  }

  checkEligibility() {
    if (!this.companyValue || !this.aidsValue) {
      console.warn("Données manquantes pour l'analyse:", {
        company: !!this.companyValue,
        aids: !!this.aidsValue
      })
      return
    }

    console.log("🔍 Début analyse d'éligibilité")
    console.log("📊 Company data:", this.companyValue)
    console.log("🎯 Aids available:", this.aidsValue.length)

    const eligibleAids = []
    const improvementAids = []
    const ineligibleAids = []

    this.aidsValue.forEach((aid, index) => {
      console.log(`\n🔍 Analyse aide ${index + 1}:`, aid.titre)
      const eligibilityResult = this.evaluateEligibility(aid, this.companyValue)
      console.log(`📋 Résultat:`, eligibilityResult)

      switch(eligibilityResult.status) {
        case 'eligible':
          eligibleAids.push({ aid, result: eligibilityResult })
          break
        case 'potential':
          improvementAids.push({ aid, result: eligibilityResult })
          break
        case 'ineligible':
          ineligibleAids.push({ aid, result: eligibilityResult })
          break
      }
    })

    console.log("🎯 Résultats finaux:", {
      eligible: eligibleAids.length,
      potential: improvementAids.length,
      ineligible: ineligibleAids.length
    })

    this.displayResults(eligibleAids, improvementAids, ineligibleAids)
  }

  evaluateEligibility(aid, company) {
    const criteria = aid.conditions_eligibilite || {}
    const issues = []
    const improvements = []

    // Vérification du statut
    if (company.statut !== 'ACTIF') {
      issues.push("Entreprise non active")
      return { status: 'ineligible', issues }
    }

    // Vérification de la localisation (Bruxelles)
    if (company.adresse && !this.isBrusselsLocation(company.adresse)) {
      issues.push("Entreprise non située en Région de Bruxelles-Capitale")
      return { status: 'ineligible', issues }
    }

    // 🎯 Critères d'éligibilité plus sélectifs pour générer des diagnostics pertinents
    const aideName = aid.titre || ''

    // Simuler des critères spécifiques seulement pour quelques aides pour démonstration
    if (aideName.includes('Transition') && company.nombre_employes > 100) {
      // Seulement si vraiment trop d'employés
      improvements.push({
        issue: `Effectif trop important pour optimiser la ${aideName} (${company.nombre_employes} employés)`,
        suggestion: "Considérer une restructuration en filiales ou une réduction d'effectif"
      })
    }

    if (aideName.includes('Formation') && company.date_creation) {
      // Vérifier l'âge seulement si pertinent
      const creation = new Date(company.date_creation)
      const now = new Date()
      const ageInMonths = (now - creation) / (1000 * 60 * 60 * 24 * 30.44)

      if (ageInMonths < 6) { // Très récent
        improvements.push({
          issue: `Entreprise très récente pour la ${aideName} (${Math.floor(ageInMonths)} mois)`,
          suggestion: `Développer d'abord l'activité pendant ${Math.ceil(6 - ageInMonths)} mois supplémentaires`
        })
      }
    }

    // Vérification de la taille d'entreprise (critères existants)
    if (criteria.taille_entreprise) {
      const sizeCheck = this.checkCompanySize(company, criteria.taille_entreprise)
      if (!sizeCheck.eligible) {
        if (sizeCheck.canImprove) {
          improvements.push({
            issue: sizeCheck.message,
            suggestion: sizeCheck.improvement
          })
        } else {
          issues.push(sizeCheck.message)
        }
      }
    }

    // Vérification du secteur d'activité
    if (criteria.secteurs_eligibles && company.code_nace) {
      const sectorCheck = this.checkSector(company.code_nace, criteria.secteurs_eligibles)
      if (!sectorCheck.eligible) {
        if (sectorCheck.canImprove) {
          improvements.push({
            issue: sectorCheck.message,
            suggestion: sectorCheck.improvement
          })
        } else {
          issues.push(sectorCheck.message)
        }
      }
    }

    // Vérification de l'âge de l'entreprise
    if (criteria.age_minimum && company.date_creation) {
      const ageCheck = this.checkCompanyAge(company.date_creation, criteria.age_minimum)
      if (!ageCheck.eligible) {
        if (ageCheck.canImprove) {
          improvements.push({
            issue: ageCheck.message,
            suggestion: ageCheck.improvement
          })
        } else {
          issues.push(ageCheck.message)
        }
      }
    }

    // Déterminer le statut final
    if (issues.length > 0) {
      return { status: 'ineligible', issues }
    } else if (improvements.length > 0) {
      return { status: 'potential', improvements }
    } else {
      return { status: 'eligible', message: "Tous les critères sont remplis" }
    }
  }

  isBrusselsLocation(address) {
    const brusselsPostalCodes = /^1[0-2]\d{2}$/
    return brusselsPostalCodes.test(address.code_postal)
  }

  checkCompanySize(company, criteria) {
    const employeeCount = company.nombre_employes || 0
    const turnover = company.chiffre_affaires || 0

    // Critères PME : < 250 employés ET < 50M€ CA
    if (criteria.includes('PME')) {
      if (employeeCount > 250) {
        return {
          eligible: false,
          canImprove: employeeCount <= 300, // Possible si pas trop grand
          message: `Entreprise trop grande (${employeeCount} employés)`,
          improvement: "Réduire l'effectif à moins de 250 employés ou restructurer en filiales"
        }
      }
      if (turnover > 50000000) {
        return {
          eligible: false,
          canImprove: turnover <= 60000000,
          message: `Chiffre d'affaires trop élevé (${this.formatAmount(turnover)})`,
          improvement: "Réorganiser la structure pour séparer certaines activités"
        }
      }
    }

    // Critères TPE : < 10 employés
    if (criteria.includes('TPE') && employeeCount >= 10) {
      return {
        eligible: false,
        canImprove: employeeCount <= 15,
        message: `Trop d'employés pour une TPE (${employeeCount})`,
        improvement: "Réduire l'effectif à moins de 10 employés"
      }
    }

    return { eligible: true }
  }

  checkSector(naceCode, eligibleSectors) {
    const sector = naceCode.substring(0, 2)
    const isEligible = eligibleSectors.some(eligibleSector =>
      naceCode.startsWith(eligibleSector) || sector === eligibleSector
    )

    if (!isEligible) {
      return {
        eligible: false,
        canImprove: true,
        message: `Secteur ${sector} non éligible`,
        improvement: "Considérer une diversification d'activité ou vérifier les codes NACE secondaires"
      }
    }

    return { eligible: true }
  }

  checkCompanyAge(creationDate, minimumMonths) {
    const now = new Date()
    const creation = new Date(creationDate)
    const ageInMonths = (now - creation) / (1000 * 60 * 60 * 24 * 30.44)

    if (ageInMonths < minimumMonths) {
      const remainingMonths = Math.ceil(minimumMonths - ageInMonths)
      return {
        eligible: false,
        canImprove: true,
        message: `Entreprise trop récente (${Math.floor(ageInMonths)} mois)`,
        improvement: `Attendre ${remainingMonths} mois supplémentaires`
      }
    }

    return { eligible: true }
  }

  displayResults(eligible, potential, ineligible) {
    // Afficher toutes les aides ensemble d'abord
    this.displayAllAids(eligible, potential, ineligible)

    // Afficher une section diagnostic séparée seulement si nécessaire
    if (potential.length > 0) {
      this.displayDiagnosticSection(potential)
    }

    // Afficher les résultats
    document.getElementById('eligibility-results').style.display = 'block'

    // Activer le bouton suivant
    document.getElementById('proceed-to-calculator').disabled = false

    // 🎯 Transmettre les données au calculateur d'aides
    this.passDataToCalculator(eligible, potential)
  }

  displayAllAids(eligible, potential, ineligible) {
    // Mettre à jour le compteur total
    const totalAids = eligible.length + potential.length + ineligible.length
    document.getElementById('eligible-count').textContent = totalAids

    // Créer une liste unifiée avec toutes les aides
    const allAids = [
      ...eligible.map(({aid}) => ({aid, status: 'eligible'})),
      ...potential.map(({aid}) => ({aid, status: 'potential'})),
      ...ineligible.map(({aid}) => ({aid, status: 'ineligible'}))
    ]

    const container = document.getElementById('eligible-aids')
    container.innerHTML = allAids.map(({aid, status}) => {
      const statusClass = status === 'eligible' ? 'success' : status === 'potential' ? 'warning' : 'secondary'
      const statusIcon = status === 'eligible' ? 'check-circle' : status === 'potential' ? 'tools' : 'info-circle'
      const statusText = status === 'eligible' ? 'Éligible' : status === 'potential' ? 'Potentielle' : 'Non éligible'

      return `
        <div class="col-md-6 mb-3">
          <div class="card border-${statusClass} h-100">
            <div class="card-body">
              <h6 class="card-title">${aid.titre || 'Aide non spécifiée'}</h6>
              <span class="badge bg-${statusClass} mb-2">
                <i class="fas fa-${statusIcon} me-1"></i>${statusText}
              </span>
              <p class="card-text small">${aid.description || 'Description non disponible'}</p>
              <div class="small text-muted">
                <strong>Montant max:</strong> ${this.formatAmount(aid.montant_max)}<br>
                <strong>Taux:</strong> ${aid.taux_aide || 'Non spécifié'}%
              </div>
            </div>
          </div>
        </div>
      `
    }).join('')
  }

  displayDiagnosticSection(potential) {
    // Créer une section diagnostic séparée
    const diagnosticHtml = `
      <div class="mt-4 p-3 bg-light rounded border-warning border">
        <h6 class="text-warning mb-3">
          <i class="fas fa-lightbulb me-2"></i>
          Conseils d'Optimisation (${potential.length} aide(s) à améliorer)
        </h6>
        <div class="accordion" id="diagnostic-accordion">
          ${potential.map(({ aid, result }, index) => `
            <div class="accordion-item">
              <h2 class="accordion-header">
                <button class="accordion-button collapsed" type="button"
                        data-bs-toggle="collapse" data-bs-target="#diagnostic-${index}">
                  <strong>${aid.titre}</strong>
                  <span class="badge bg-warning ms-2">${result.improvements.length} conseil(s)</span>
                </button>
              </h2>
              <div id="diagnostic-${index}" class="accordion-collapse collapse"
                   data-bs-parent="#diagnostic-accordion">
                <div class="accordion-body">
                  ${result.improvements.map(improvement => `
                    <div class="alert alert-warning mb-2">
                      <strong>💡 Conseil:</strong> ${improvement.issue}<br>
                      <strong>🎯 Action:</strong> ${improvement.suggestion}
                    </div>
                  `).join('')}
                </div>
              </div>
            </div>
          `).join('')}
        </div>
      </div>
    `

    // Ajouter la section diagnostic après les aides
    const container = document.getElementById('eligible-aids').parentElement
    container.insertAdjacentHTML('afterend', diagnosticHtml)
  }

  passDataToCalculator(eligible, potential) {
    // Trouver l'élément du calculateur d'aides
    const calculatorElement = document.querySelector('[data-controller*="aid-calculator"]')

    if (calculatorElement) {
      // Préparer les données des aides éligibles pour le calculateur
      const eligibleAids = eligible.map(({ aid }) => aid)
      const potentialAids = potential.map(({ aid }) => aid)

      // 🎯 Toutes les aides pour le calculateur (les 14 aides)
      const allAids = this.aidsValue || []

      // Transmettre via un événement personnalisé
      const event = new CustomEvent('eligibility:results', {
        detail: {
          company: this.companyValue,
          eligibleAids: eligibleAids,
          potentialAids: potentialAids,
          allAids: allAids,
          allResults: { eligible, potential }
        }
      })

      calculatorElement.dispatchEvent(event)
      console.log("📤 Données transmises au calculateur:", {
        eligible: eligibleAids.length,
        potential: potentialAids.length,
        total: allAids.length
      })
    } else {
      console.warn("⚠️ Calculateur d'aides non trouvé")
    }
  }

  displayEligibleAids(eligible) {
    const container = document.getElementById('eligible-aids')
    container.innerHTML = eligible.map(({ aid }) => `
      <div class="col-md-6 mb-3">
        <div class="card border-success h-100">
          <div class="card-body">
            <h6 class="card-title text-success">${aid.titre || 'Aide non spécifiée'}</h6>
            <p class="card-text small">${aid.description || 'Description non disponible'}</p>
            <div class="small text-muted">
              <strong>Montant max:</strong> ${this.formatAmount(aid.montant_max)}<br>
              <strong>Taux:</strong> ${aid.taux_aide || 'Non spécifié'}%
            </div>
          </div>
        </div>
      </div>
    `).join('')
  }

  displayPotentialAids(potential) {
    const container = document.getElementById('improvement-aids')
    container.innerHTML = potential.map(({ aid, result }, index) => `
      <div class="accordion-item">
        <h2 class="accordion-header">
          <button class="accordion-button collapsed" type="button"
                  data-bs-toggle="collapse" data-bs-target="#improvement-${index}">
            <strong>${aid.titre || 'Aide non spécifiée'}</strong>
            <span class="badge bg-warning ms-2">${result.improvements.length} amélioration(s)</span>
          </button>
        </h2>
        <div id="improvement-${index}" class="accordion-collapse collapse">
          <div class="accordion-body">
            <p class="mb-3">${aid.description || 'Description non disponible'}</p>
            <h6 class="text-warning">Améliorations requises:</h6>
            <ul class="list-group list-group-flush">
              ${result.improvements.map(improvement => `
                <li class="list-group-item">
                  <strong>Problème:</strong> ${improvement.issue}<br>
                  <strong>Solution:</strong> ${improvement.suggestion}
                </li>
              `).join('')}
            </ul>
          </div>
        </div>
      </div>
    `).join('')
  }

  displayIneligibleAids(ineligible) {
    const container = document.getElementById('ineligible-aids')
    container.innerHTML = ineligible.map(({ aid, result }) => `
      <div class="card border-light mb-2">
        <div class="card-body">
          <h6 class="card-title text-muted">${aid.titre || 'Aide non spécifiée'}</h6>
          <div class="small text-danger">
            ${result.issues.map(issue => `<div>• ${issue}</div>`).join('')}
          </div>
        </div>
      </div>
    `).join('')
  }

  formatAmount(amount) {
    if (!amount || amount === 'Non spécifié') return 'Non spécifié'

    // Convertir en nombre si c'est une string
    const numericAmount = typeof amount === 'string' ? parseFloat(amount) : amount

    if (isNaN(numericAmount)) return 'Non spécifié'

    return new Intl.NumberFormat('fr-BE', { style: 'currency', currency: 'EUR' }).format(numericAmount)
  }

  showLoading() {
    document.getElementById('eligibility-loading').style.display = 'block'
    document.getElementById('eligibility-results').style.display = 'none'
  }

  hideLoading() {
    document.getElementById('eligibility-loading').style.display = 'none'
  }

  // Méthode appelée depuis le workflow
  companyValueChanged() {
    if (this.companyValue && this.aidsValue) {
      this.checkEligibility()
    }
  }
}
