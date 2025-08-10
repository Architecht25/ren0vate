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
      forme_juridique: "Société privée à responsabilité limitée"
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

    // Vérification de la taille d'entreprise
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
    // Logique simplifiée - à adapter selon les vraies données
    const employeeCount = company.nombre_employes || 0
    const turnover = company.chiffre_affaires || 0

    if (criteria.includes('PME') && (employeeCount > 250 || turnover > 50000000)) {
      return {
        eligible: false,
        canImprove: false,
        message: "Entreprise trop grande (> 250 employés ou > 50M€ CA)"
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
    // Mettre à jour les compteurs
    document.getElementById('eligible-count').textContent = eligible.length

    // Afficher les aides éligibles
    this.displayEligibleAids(eligible)

    // Afficher les aides potentielles avec améliorations
    if (potential.length > 0) {
      this.displayPotentialAids(potential)
      document.getElementById('improvement-section').style.display = 'block'
    }

    // Afficher les aides non éligibles
    if (ineligible.length > 0) {
      this.displayIneligibleAids(ineligible)
      document.getElementById('ineligible-section').style.display = 'block'
    }

    // Afficher les résultats
    document.getElementById('eligibility-results').style.display = 'block'

    // Activer le bouton suivant si au moins une aide est éligible
    if (eligible.length > 0) {
      document.getElementById('proceed-to-calculator').disabled = false
    }

    // 🎯 NOUVEAU: Transmettre les données au calculateur d'aides
    this.passDataToCalculator(eligible, potential)
  }

  passDataToCalculator(eligible, potential) {
    // Trouver l'élément du calculateur d'aides
    const calculatorElement = document.querySelector('[data-controller*="aid-calculator"]')

    if (calculatorElement) {
      // Préparer les données des aides éligibles pour le calculateur
      const eligibleAids = eligible.map(({ aid }) => aid)
      const potentialAids = potential.map(({ aid }) => aid)

      // Transmettre via un événement personnalisé
      const event = new CustomEvent('eligibility:results', {
        detail: {
          company: this.companyValue,
          eligibleAids: eligibleAids,
          potentialAids: potentialAids,
          allResults: { eligible, potential }
        }
      })

      calculatorElement.dispatchEvent(event)
      console.log("📤 Données transmises au calculateur:", {
        eligible: eligibleAids.length,
        potential: potentialAids.length
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
            <h6 class="card-title text-success">${aid.nom}</h6>
            <p class="card-text small">${aid.description_courte || aid.description}</p>
            <div class="small text-muted">
              <strong>Montant max:</strong> ${this.formatAmount(aid.montant_maximum)}<br>
              <strong>Taux:</strong> ${aid.taux_aide}%
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
            <strong>${aid.nom}</strong>
            <span class="badge bg-warning ms-2">${result.improvements.length} amélioration(s)</span>
          </button>
        </h2>
        <div id="improvement-${index}" class="accordion-collapse collapse">
          <div class="accordion-body">
            <p class="mb-3">${aid.description_courte || aid.description}</p>
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
          <h6 class="card-title text-muted">${aid.nom}</h6>
          <div class="small text-danger">
            ${result.issues.map(issue => `<div>• ${issue}</div>`).join('')}
          </div>
        </div>
      </div>
    `).join('')
  }

  formatAmount(amount) {
    if (!amount) return 'Non spécifié'
    return new Intl.NumberFormat('fr-BE', { style: 'currency', currency: 'EUR' }).format(amount)
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
