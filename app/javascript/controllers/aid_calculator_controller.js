import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["totalInvestment", "totalAids", "aidCalculations", "detailedResults"]
  static values = {
    company: Object,
    eligibleAids: Array,
    potentialAids: Array
  }

  connect() {
    console.log("Aid Calculator controller connected")
    this.setupInvestmentListeners()
    this.setupEligibilityListener()
  }

  setupEligibilityListener() {
    // 🎯 Écouter les résultats d'éligibilité de l'étape 2
    this.element.addEventListener('eligibility:results', (event) => {
      console.log("📥 Données reçues de l'éligibilité:", event.detail)

      this.companyValue = event.detail.company
      this.eligibleAidsValue = event.detail.eligibleAids
      this.potentialAidsValue = event.detail.potentialAids || []

      console.log("✅ Données mises à jour:", {
        company: !!this.companyValue,
        eligibleAids: this.eligibleAidsValue?.length || 0,
        potentialAids: this.potentialAidsValue?.length || 0
      })

      // Déclencher le calcul automatique si il y a des investissements
      this.calculateAids()
    })
  }

  setupInvestmentListeners() {
    // Écouter les changements sur tous les champs d'investissement
    const investmentInputs = this.element.querySelectorAll('input[type="number"]')
    investmentInputs.forEach(input => {
      input.addEventListener('input', () => this.calculateAids())
    })
  }

  calculateAids() {
    const investments = this.getInvestments()
    const totalInvestment = this.calculateTotalInvestment(investments)

    // Mettre à jour le total des investissements
    this.totalInvestmentTarget.textContent = this.formatCurrency(totalInvestment)

    if (totalInvestment > 0 && this.eligibleAidsValue) {
      const aidCalculations = this.calculateEachAid(investments)
      const totalAids = aidCalculations.reduce((sum, calc) => sum + calc.montant, 0)

      // Mettre à jour l'affichage
      this.totalAidsTarget.textContent = this.formatCurrency(totalAids)
      this.displayAidCalculations(aidCalculations)

      // Afficher les résultats détaillés si nécessaire
      if (totalAids > 0) {
        this.detailedResultsTarget.style.display = 'block'
        this.displayDetailedCalculations(aidCalculations)
      }
    } else {
      this.totalAidsTarget.textContent = '0 €'
      this.aidCalculationsTarget.innerHTML = ''
      this.detailedResultsTarget.style.display = 'none'
    }
  }

  getInvestments() {
    return {
      consultation: parseFloat(document.getElementById('investment-consultation').value) || 0,
      equipment: parseFloat(document.getElementById('investment-equipment').value) || 0,
      mobility: parseFloat(document.getElementById('investment-mobility').value) || 0,
      other: parseFloat(document.getElementById('investment-other').value) || 0
    }
  }

  calculateTotalInvestment(investments) {
    return Object.values(investments).reduce((sum, amount) => sum + amount, 0)
  }

  calculateEachAid(investments) {
    return this.eligibleAidsValue.map(aid => {
      const applicableInvestment = this.getApplicableInvestment(aid, investments)
      const montant = this.calculateAidAmount(aid, applicableInvestment)

      return {
        aid,
        applicableInvestment,
        montant,
        details: this.getCalculationDetails(aid, applicableInvestment, montant)
      }
    }).filter(calc => calc.montant > 0)
  }

  getApplicableInvestment(aid, investments) {
    // Déterminer quels investissements sont applicables selon le type d'aide
    switch(aid.categorie) {
      case 'Transition économique':
        if (aid.nom.includes('Consultance')) {
          return investments.consultation + investments.other
        } else if (aid.nom.includes('Investissements')) {
          return investments.equipment + investments.other
        }
        break
      case 'Mobilité':
        return investments.mobility
      default:
        return investments.consultation + investments.equipment + investments.mobility + investments.other
    }
  }

  calculateAidAmount(aid, applicableInvestment) {
    if (applicableInvestment === 0) return 0

    const tauxAide = parseFloat(aid.taux_aide) / 100
    let montantCalcule = applicableInvestment * tauxAide

    // Appliquer les limites
    if (aid.montant_minimum && montantCalcule < aid.montant_minimum) {
      return 0 // Investissement trop faible
    }

    if (aid.montant_maximum && montantCalcule > aid.montant_maximum) {
      montantCalcule = aid.montant_maximum
    }

    return Math.round(montantCalcule)
  }

  getCalculationDetails(aid, applicableInvestment, montant) {
    const tauxAide = parseFloat(aid.taux_aide)

    let details = {
      investissementApplicable: applicableInvestment,
      tauxApplique: tauxAide,
      montantBrut: applicableInvestment * (tauxAide / 100),
      montantFinal: montant,
      limitesAppliquees: []
    }

    if (aid.montant_minimum && details.montantBrut < aid.montant_minimum) {
      details.limitesAppliquees.push(`Montant minimum: ${this.formatCurrency(aid.montant_minimum)}`)
    }

    if (aid.montant_maximum && details.montantBrut > aid.montant_maximum) {
      details.limitesAppliquees.push(`Montant maximum: ${this.formatCurrency(aid.montant_maximum)}`)
    }

    return details
  }

  displayAidCalculations(calculations) {
    this.aidCalculationsTarget.innerHTML = calculations.map(calc => `
      <div class="card mb-2">
        <div class="card-body p-2">
          <div class="d-flex justify-content-between align-items-center">
            <div>
              <strong class="small">${calc.aid.nom}</strong>
              <div class="text-muted small">
                ${this.formatCurrency(calc.applicableInvestment)} × ${calc.aid.taux_aide}%
              </div>
            </div>
            <div class="text-end">
              <strong class="text-success">${this.formatCurrency(calc.montant)}</strong>
            </div>
          </div>
        </div>
      </div>
    `).join('')
  }

  displayDetailedCalculations(calculations) {
    const container = document.getElementById('detailed-calculations')
    container.innerHTML = calculations.map((calc, index) => `
      <div class="accordion-item">
        <h2 class="accordion-header">
          <button class="accordion-button collapsed" type="button"
                  data-bs-toggle="collapse" data-bs-target="#detail-${index}">
            <div class="d-flex justify-content-between w-100 me-3">
              <span><strong>${calc.aid.nom}</strong></span>
              <span class="text-success"><strong>${this.formatCurrency(calc.montant)}</strong></span>
            </div>
          </button>
        </h2>
        <div id="detail-${index}" class="accordion-collapse collapse">
          <div class="accordion-body">
            <div class="row">
              <div class="col-md-6">
                <h6>Calcul détaillé</h6>
                <table class="table table-sm">
                  <tr>
                    <td>Investissement applicable:</td>
                    <td class="text-end"><strong>${this.formatCurrency(calc.applicableInvestment)}</strong></td>
                  </tr>
                  <tr>
                    <td>Taux d'aide:</td>
                    <td class="text-end"><strong>${calc.aid.taux_aide}%</strong></td>
                  </tr>
                  <tr>
                    <td>Montant brut:</td>
                    <td class="text-end">${this.formatCurrency(calc.details.montantBrut)}</td>
                  </tr>
                  ${calc.details.limitesAppliquees.map(limite => `
                    <tr class="text-muted">
                      <td colspan="2"><small>${limite}</small></td>
                    </tr>
                  `).join('')}
                  <tr class="table-success">
                    <td><strong>Montant final:</strong></td>
                    <td class="text-end"><strong>${this.formatCurrency(calc.montant)}</strong></td>
                  </tr>
                </table>
              </div>
              <div class="col-md-6">
                <h6>Informations sur l'aide</h6>
                <p class="small">${calc.aid.description_courte || calc.aid.description}</p>
                <div class="small">
                  <strong>Modalités de paiement:</strong><br>
                  ${this.formatModalitesPaiement(calc.aid.modalites_paiement)}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    `).join('')
  }

  formatModalitesPaiement(modalites) {
    if (!modalites) return 'Non spécifiées'

    if (typeof modalites === 'string') return modalites

    if (Array.isArray(modalites)) {
      return modalites.map(m => `• ${m}`).join('<br>')
    }

    if (typeof modalites === 'object') {
      return Object.entries(modalites)
        .map(([key, value]) => `<strong>${key}:</strong> ${value}`)
        .join('<br>')
    }

    return 'Format non reconnu'
  }

  formatCurrency(amount) {
    return new Intl.NumberFormat('fr-BE', {
      style: 'currency',
      currency: 'EUR',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(amount)
  }

  generateSummary() {
    const investments = this.getInvestments()
    const totalInvestment = this.calculateTotalInvestment(investments)
    const aidCalculations = this.calculateEachAid(investments)
    const totalAids = aidCalculations.reduce((sum, calc) => sum + calc.montant, 0)

    // Créer un résumé détaillé
    const summary = {
      company: this.companyValue,
      investments,
      totalInvestment,
      aids: aidCalculations,
      totalAids,
      generatedAt: new Date().toISOString()
    }

    // Déclencher la génération du PDF ou l'affichage du résumé
    this.dispatch("summaryGenerated", { detail: summary })

    // Pour l'instant, afficher dans la console
    console.log("Résumé généré:", summary)

    // Afficher une notification
    this.showNotification("Résumé généré avec succès!", "success")
  }

  startApplications() {
    const aidCalculations = this.calculateEachAid(this.getInvestments())
    const eligibleAids = aidCalculations.filter(calc => calc.montant > 0)

    if (eligibleAids.length === 0) {
      this.showNotification("Aucune aide calculée pour démarrer les demandes", "warning")
      return
    }

    // Rediriger vers la page de demandes ou ouvrir un assistant
    this.dispatch("applicationsStarted", {
      detail: {
        aids: eligibleAids,
        company: this.companyValue
      }
    })

    // Pour l'instant, afficher une notification
    this.showNotification(`Préparation des demandes pour ${eligibleAids.length} aide(s)`, "info")
  }

  showNotification(message, type = "info") {
    // Créer une notification Bootstrap
    const notification = document.createElement('div')
    notification.className = `alert alert-${type} alert-dismissible fade show position-fixed`
    notification.style.cssText = 'top: 20px; right: 20px; z-index: 9999; min-width: 300px;'
    notification.innerHTML = `
      ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `

    document.body.appendChild(notification)

    // Retirer automatiquement après 5 secondes
    setTimeout(() => {
      if (notification.parentNode) {
        notification.remove()
      }
    }, 5000)
  }

  // Méthode appelée quand les aides éligibles changent
  eligibleAidsValueChanged() {
    if (this.eligibleAidsValue) {
      this.calculateAids()
    }
  }
}
