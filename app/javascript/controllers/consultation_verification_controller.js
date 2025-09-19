// Stimulus controller for consultant verification functionality
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bceInput", "consultantType", "result"]

  connect() {
    console.log("Consultation verification controller connected")
  }

  formatBceNumber(event) {
    const input = event.target
    let value = input.value.replace(/[^0-9]/g, '')

    if (value.length > 10) {
      value = value.substring(0, 10)
    }

    if (value.length >= 4) {
      value = value.substring(0, 4) + '.' + value.substring(4)
    }
    if (value.length >= 8) {
      value = value.substring(0, 8) + '.' + value.substring(8)
    }

    input.value = value
  }

  async verifyConsultant(event) {
    event.preventDefault()

    const bceNumber = this.bceInputTarget.value
    const consultantType = this.consultantTypeTarget.value

    if (!bceNumber || bceNumber.length < 13) {
      this.showError("Veuillez saisir un numéro BCE valide (format: 0123.456.789)")
      return
    }

    // Disable button and show loading
    const button = event.target
    const originalContent = button.innerHTML
    button.disabled = true
    button.innerHTML = '<i class="bi bi-hourglass-split me-1"></i>Vérification...'

    try {
      const response = await fetch('/api/entreprises/bce_lookup', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          numero_bce: bceNumber,
          consultant_type: consultantType
        })
      })

      const data = await response.json()

      if (data.success) {
        this.showConsultantResult(data.data, consultantType)
      } else {
        this.showError(data.error || "Erreur lors de la vérification")
      }
    } catch (error) {
      console.error('Error verifying consultant:', error)
      this.showError("Erreur de connexion. Veuillez réessayer.")
    } finally {
      // Re-enable button
      button.disabled = false
      button.innerHTML = originalContent
    }
  }

  showConsultantResult(data, consultantType) {
    const eligibility = this.checkConsultantEligibility(data, consultantType)

    const resultHtml = `
      <div class="card ${eligibility.eligible ? 'border-success' : 'border-danger'}">
        <div class="card-header ${eligibility.eligible ? 'bg-success' : 'bg-danger'} text-white">
          <h6 class="mb-0">
            <i class="bi bi-${eligibility.eligible ? 'check-circle' : 'x-circle'} me-2"></i>
            ${eligibility.eligible ? 'Consultant éligible' : 'Consultant non éligible'}
          </h6>
        </div>
        <div class="card-body">
          <div class="row g-3">
            <div class="col-md-6">
              <h6 class="text-primary mb-3">Informations entreprise</h6>
              <ul class="list-unstyled">
                <li><strong>Dénomination :</strong> ${data.denomination}</li>
                <li><strong>Numéro BCE :</strong> ${data.numero_bce}</li>
                <li><strong>Forme juridique :</strong> ${data.forme_juridique}</li>
                <li><strong>Statut :</strong> ${data.statut}</li>
                <li><strong>Adresse :</strong> ${data.adresse.rue} ${data.adresse.numero}, ${data.adresse.code_postal} ${data.adresse.commune}</li>
              </ul>
            </div>
            <div class="col-md-6">
              <h6 class="text-info mb-3">Codes NACE</h6>
              <div class="mb-3">
                <strong>Principal :</strong> ${data.code_nace || 'N/A'}
              </div>
              ${data.codes_nace && data.codes_nace.length > 0 ? `
                <div class="small">
                  <strong>Autres activités :</strong>
                  <ul class="mt-1">
                    ${data.codes_nace.slice(0, 3).map(nace =>
                      `<li>${nace.code} - ${nace.classification}</li>`
                    ).join('')}
                  </ul>
                </div>
              ` : ''}
            </div>
          </div>

          <hr>

          <div class="row g-3">
            <div class="col-12">
              <h6 class="text-warning mb-3">Critères d'éligibilité</h6>
              <div class="row g-2">
                ${eligibility.criteria.map(criterion => `
                  <div class="col-md-6">
                    <div class="d-flex align-items-center">
                      <i class="bi bi-${criterion.status ? 'check-circle text-success' : 'x-circle text-danger'} me-2"></i>
                      <span class="${criterion.status ? 'text-success' : 'text-danger'}">${criterion.name}</span>
                    </div>
                    ${criterion.details ? `<small class="text-muted ms-3">${criterion.details}</small>` : ''}
                  </div>
                `).join('')}
              </div>
            </div>
          </div>

          ${eligibility.recommendations.length > 0 ? `
            <hr>
            <div class="alert alert-info">
              <h6 class="alert-heading">Recommandations</h6>
              <ul class="mb-0">
                ${eligibility.recommendations.map(rec => `<li>${rec}</li>`).join('')}
              </ul>
            </div>
          ` : ''}
        </div>
      </div>
    `

    this.resultTarget.innerHTML = resultHtml
    this.resultTarget.style.display = 'block'
  }

  checkConsultantEligibility(data, consultantType) {
    const criteria = []
    let eligible = true
    const recommendations = []

    // Critère 1: Statut actif
    const isActive = data.statut === 'ACTIF'
    criteria.push({
      name: 'Entreprise active',
      status: isActive,
      details: isActive ? 'Statut ACTIF confirmé' : `Statut: ${data.statut}`
    })
    if (!isActive) eligible = false

    // Critère 2: Adresse Bruxelles
    const isBrussels = this.isBrusselsAddress(data.adresse)
    criteria.push({
      name: 'Siège social à Bruxelles',
      status: isBrussels,
      details: isBrussels ? 'Code postal bruxellois confirmé' : 'Siège social hors Bruxelles'
    })
    if (!isBrussels) {
      eligible = false
      recommendations.push("Le consultant doit avoir son siège social à Bruxelles pour être éligible")
    }

    // Critère 3: Code NACE éligible
    const eligibleNaceCodes = ['70.22', '71.11', '71.12', '74.90']
    const hasEligibleNace = this.hasEligibleNaceCode(data, eligibleNaceCodes)
    criteria.push({
      name: 'Code NACE éligible',
      status: hasEligibleNace.eligible,
      details: hasEligibleNace.details
    })
    if (!hasEligibleNace.eligible) {
      eligible = false
      recommendations.push("Le consultant doit avoir un code NACE de conseil, architecture ou ingénierie")
    }

    // Critère 4: Ancienneté (si date de création disponible)
    if (data.date_creation) {
      const isOldEnough = this.checkCompanyAge(data.date_creation)
      criteria.push({
        name: 'Ancienneté suffisante (2+ ans)',
        status: isOldEnough.eligible,
        details: isOldEnough.details
      })
      if (!isOldEnough.eligible) {
        eligible = false
        recommendations.push("Le consultant doit avoir au moins 2 ans d'ancienneté")
      }
    }

    // Recommandations générales
    if (eligible) {
      recommendations.push("Vérifiez les assurances responsabilité civile professionnelle")
      recommendations.push("Demandez des références sur des projets similaires")
      recommendations.push("Consultez les certifications et qualifications spécialisées")
    }

    return {
      eligible,
      criteria,
      recommendations
    }
  }

  isBrusselsAddress(adresse) {
    const brusselsPostalCodes = [
      '1000', '1020', '1030', '1040', '1050', '1060', '1070', '1080',
      '1081', '1082', '1083', '1090', '1120', '1130', '1140', '1150',
      '1160', '1170', '1180', '1190', '1200', '1210'
    ]
    return brusselsPostalCodes.includes(adresse.code_postal)
  }

  hasEligibleNaceCode(data, eligibleCodes) {
    // Vérifier le code principal
    if (data.code_nace && eligibleCodes.includes(data.code_nace)) {
      return {
        eligible: true,
        details: `Code principal ${data.code_nace} éligible`
      }
    }

    // Vérifier les codes secondaires
    if (data.codes_nace && data.codes_nace.length > 0) {
      for (const nace of data.codes_nace) {
        if (eligibleCodes.includes(nace.code)) {
          return {
            eligible: true,
            details: `Code ${nace.code} (${nace.classification}) éligible`
          }
        }
      }
    }

    return {
      eligible: false,
      details: 'Aucun code NACE éligible trouvé'
    }
  }

  checkCompanyAge(dateCreation) {
    const creationDate = new Date(dateCreation)
    const twoYearsAgo = new Date()
    twoYearsAgo.setFullYear(twoYearsAgo.getFullYear() - 2)

    const eligible = creationDate <= twoYearsAgo
    const years = ((new Date() - creationDate) / (1000 * 60 * 60 * 24 * 365)).toFixed(1)

    return {
      eligible,
      details: eligible ? `${years} ans d'activité` : `Seulement ${years} ans d'activité`
    }
  }

  showError(message) {
    this.resultTarget.innerHTML = `
      <div class="alert alert-danger">
        <i class="bi bi-exclamation-triangle me-2"></i>
        ${message}
      </div>
    `
    this.resultTarget.style.display = 'block'
  }

  saveConsultant(event) {
    event.preventDefault()
    // TODO: Implement save functionality
    alert("Fonctionnalité de sauvegarde à implémenter")
  }
}
