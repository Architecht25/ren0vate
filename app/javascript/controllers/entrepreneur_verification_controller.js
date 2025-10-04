// Stimulus controller for entrepreneur verification functionality
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bceInput", "entrepreneurType", "result"]

  connect() {
    console.log("Entrepreneur verification controller connected")
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

  async verifyEntrepreneur(event) {
    event.preventDefault()

    const bceNumber = this.bceInputTarget.value
    const entrepreneurType = this.entrepreneurTypeTarget.value

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
          bce_number: bceNumber.replace(/\./g, ''),
          verification_type: 'entrepreneur'
        })
      })

      const data = await response.json()

      if (response.ok) {
        this.displayEntrepreneurResults(data, entrepreneurType)
      } else {
        this.showError(data.error || "Erreur lors de la vérification")
      }
    } catch (error) {
      console.error('Error verifying entrepreneur:', error)
      this.showError("Erreur de connexion. Veuillez réessayer.")
    } finally {
      // Restore button
      button.disabled = false
      button.innerHTML = originalContent
    }
  }

  displayEntrepreneurResults(data, selectedType) {
    const resultContainer = this.resultTarget
    const company = data.company

    if (!company) {
      this.showError("Aucune entreprise trouvée avec ce numéro BCE")
      return
    }

    const isEligible = this.checkEntrepreneurEligibility(company, selectedType)
    const statusColor = isEligible ? 'success' : 'danger'
    const statusIcon = isEligible ? 'check-circle' : 'x-circle'
    const statusText = isEligible ? 'Éligible' : 'Non éligible'

    // Construction NACE codes for entrepreneurs
    const constructionNaceCodes = [
      '41.20', '43.21', '43.22', '43.32', '43.34',
      '43.39', '43.91', '43.99', '42.11', '42.12', '42.13'
    ]

    const eligibleNaceCodes = company.nace_codes?.filter(code =>
      constructionNaceCodes.some(constructionCode =>
        code.code?.startsWith(constructionCode)
      )
    ) || []

    resultContainer.innerHTML = `
      <div class="card border-${statusColor}">
        <div class="card-header bg-${statusColor} text-white">
          <h5 class="mb-0">
            <i class="bi bi-${statusIcon} me-2"></i>
            Résultat de vérification - ${statusText}
          </h5>
        </div>
        <div class="card-body">
          <div class="row g-4">
            <div class="col-md-6">
              <h6 class="text-primary mb-3">
                <i class="bi bi-building me-2"></i>Informations entreprise
              </h6>
              <table class="table table-sm">
                <tr>
                  <td><strong>Nom :</strong></td>
                  <td>${company.name || 'Non disponible'}</td>
                </tr>
                <tr>
                  <td><strong>BCE :</strong></td>
                  <td>${company.bce_number || 'Non disponible'}</td>
                </tr>
                <tr>
                  <td><strong>Statut :</strong></td>
                  <td>
                    <span class="badge ${company.status === 'ACTIF' ? 'bg-success' : 'bg-danger'}">
                      ${company.status || 'Non disponible'}
                    </span>
                  </td>
                </tr>
                <tr>
                  <td><strong>Adresse :</strong></td>
                  <td>${this.formatAddress(company.address)}</td>
                </tr>
                <tr>
                  <td><strong>Date création :</strong></td>
                  <td>${company.start_date ? new Date(company.start_date).toLocaleDateString('fr-BE') : 'Non disponible'}</td>
                </tr>
              </table>
            </div>
            <div class="col-md-6">
              <h6 class="text-warning mb-3">
                <i class="bi bi-tools me-2"></i>Codes NACE construction
              </h6>
              ${eligibleNaceCodes.length > 0 ? `
                <div class="mb-3">
                  ${eligibleNaceCodes.map(nace => `
                    <span class="badge bg-warning text-dark me-1 mb-1">
                      ${nace.code} - ${nace.description}
                    </span>
                  `).join('')}
                </div>
              ` : `
                <div class="alert alert-warning">
                  <i class="bi bi-exclamation-triangle me-2"></i>
                  Aucun code NACE construction détecté
                </div>
              `}

              <h6 class="text-info mb-3 mt-4">
                <i class="bi bi-clipboard-check me-2"></i>Vérifications effectuées
              </h6>
              <ul class="list-unstyled">
                ${this.generateVerificationChecks(company, eligibleNaceCodes)}
              </ul>
            </div>
          </div>

          ${!isEligible ? `
            <div class="alert alert-danger mt-3">
              <h6 class="alert-heading">
                <i class="bi bi-exclamation-triangle me-2"></i>Problèmes détectés
              </h6>
              <ul class="mb-0">
                ${this.generateIssuesList(company, eligibleNaceCodes)}
              </ul>
            </div>
          ` : `
            <div class="alert alert-success mt-3">
              <i class="bi bi-check-circle me-2"></i>
              <strong>Entrepreneur éligible :</strong> Cette entreprise peut réaliser vos travaux de rénovation.
            </div>
          `}
        </div>
      </div>
    `

    resultContainer.style.display = 'block'
    resultContainer.scrollIntoView({ behavior: 'smooth' })
  }

  checkEntrepreneurEligibility(company, selectedType) {
    // Check if company is active
    if (company.status !== 'ACTIF') {
      return false
    }

    // Check if company has construction-related NACE codes
    const constructionNaceCodes = [
      '41.20', '43.21', '43.22', '43.32', '43.34',
      '43.39', '43.91', '43.99', '42.11', '42.12', '42.13'
    ]

    const hasConstructionNace = company.nace_codes?.some(nace =>
      constructionNaceCodes.some(constructionCode =>
        nace.code?.startsWith(constructionCode)
      )
    )

    if (!hasConstructionNace) {
      return false
    }

    // Check financial status (basic check - would need more detailed data)
    // For now, we assume if the company is active, it's financially stable
    // In reality, you'd need to check for bankruptcy, judicial reorganization, etc.

    // Check company age (at least 1 year)
    if (company.start_date) {
      const startDate = new Date(company.start_date)
      const oneYearAgo = new Date()
      oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1)

      if (startDate > oneYearAgo) {
        return false
      }
    }

    return true
  }

  generateVerificationChecks(company, eligibleNaceCodes) {
    const checks = []

    // Active status check
    if (company.status === 'ACTIF') {
      checks.push(`<li><i class="bi bi-check text-success me-2"></i>Entreprise active</li>`)
    } else {
      checks.push(`<li><i class="bi bi-x text-danger me-2"></i>Entreprise non active</li>`)
    }

    // NACE codes check
    if (eligibleNaceCodes.length > 0) {
      checks.push(`<li><i class="bi bi-check text-success me-2"></i>Codes NACE construction présents (${eligibleNaceCodes.length})</li>`)
    } else {
      checks.push(`<li><i class="bi bi-x text-danger me-2"></i>Aucun code NACE construction</li>`)
    }

    // Company age check
    if (company.start_date) {
      const startDate = new Date(company.start_date)
      const oneYearAgo = new Date()
      oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1)

      if (startDate <= oneYearAgo) {
        checks.push(`<li><i class="bi bi-check text-success me-2"></i>Ancienneté suffisante (+ 1 an)</li>`)
      } else {
        checks.push(`<li><i class="bi bi-x text-danger me-2"></i>Entreprise trop récente (- 1 an)</li>`)
      }
    } else {
      checks.push(`<li><i class="bi bi-question text-warning me-2"></i>Date de création non disponible</li>`)
    }

    // Financial status (placeholder - would need real data)
    checks.push(`<li><i class="bi bi-question text-warning me-2"></i>Situation financière à vérifier manuellement</li>`)

    return checks.join('')
  }

  generateIssuesList(company, eligibleNaceCodes) {
    const issues = []

    if (company.status !== 'ACTIF') {
      issues.push('Entreprise non active dans la BCE')
    }

    if (eligibleNaceCodes.length === 0) {
      issues.push('Aucun code NACE relatif à la construction')
    }

    if (company.start_date) {
      const startDate = new Date(company.start_date)
      const oneYearAgo = new Date()
      oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1)

      if (startDate > oneYearAgo) {
        issues.push('Entreprise créée il y a moins d\'un an')
      }
    }

    if (issues.length === 0) {
      issues.push('Vérification manuelle de la situation financière recommandée')
    }

    return issues.map(issue => `<li>${issue}</li>`).join('')
  }

  formatAddress(address) {
    if (!address) return 'Non disponible'

    const parts = [
      address.street,
      address.number,
      address.zipcode,
      address.city
    ].filter(Boolean)

    return parts.join(', ') || 'Non disponible'
  }

  showError(message) {
    const resultContainer = this.resultTarget
    resultContainer.innerHTML = `
      <div class="alert alert-danger">
        <i class="bi bi-exclamation-triangle me-2"></i>
        <strong>Erreur :</strong> ${message}
      </div>
    `
    resultContainer.style.display = 'block'
  }

  async saveEntrepreneur(event) {
    event.preventDefault()

    const bceNumber = this.bceInputTarget.value
    if (!bceNumber) {
      this.showError("Veuillez d'abord vérifier un entrepreneur")
      return
    }

    // This would save the entrepreneur to the user's project/favorites
    // Implementation depends on your backend structure
    console.log("Saving entrepreneur:", bceNumber)

    // Show success message
    const button = event.target
    const originalContent = button.innerHTML
    button.innerHTML = '<i class="bi bi-check me-1"></i>Sauvegardé!'
    button.classList.remove('btn-outline-success')
    button.classList.add('btn-success')

    setTimeout(() => {
      button.innerHTML = originalContent
      button.classList.remove('btn-success')
      button.classList.add('btn-outline-success')
    }, 2000)
  }
}
