import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["companyInfo", "searchButton", "loading", "input"]
  static values = {
    currentCompany: Object
  }

  connect() {
    console.log("Enhanced BCE Search controller connected")
  }

  async searchCompany(event) {
    event.preventDefault()

    const bceNumber = this.element.querySelector('#numero_entreprise_bce').value

    if (!this.isValidBCE(bceNumber)) {
      this.showError("Numéro BCE invalide. Format attendu: 0123456789")
      return
    }

    this.showLoading()

    try {
      const response = await this.fetchCompanyData(bceNumber)

      if (response.success) {
        this.displayCompanyInfo(response.data)
        this.currentCompanyValue = response.data
        this.enableNextStep()
      } else {
        this.showError(response.message || "Entreprise non trouvée")
      }
    } catch (error) {
      console.error("Erreur lors de la recherche:", error)
      this.showError("Erreur de connexion. Veuillez réessayer.")
    } finally {
      this.hideLoading()
    }
  }  async fetchCompanyData(bceNumber) {
    // Simulation d'appel API - à remplacer par vraie API BCE
    const response = await fetch(`/api/entreprises/bce/${bceNumber}`)

    if (!response.ok) {
      throw new Error('Network response was not ok')
    }

    return await response.json()
  }

  displayCompanyInfo(company) {
    // Remplir les champs d'information
    document.getElementById('company-name').textContent = company.denomination || 'N/A'
    document.getElementById('company-bce').textContent = company.numero_bce || 'N/A'
    document.getElementById('company-legal-form').textContent = company.forme_juridique || 'N/A'
    document.getElementById('company-nace').textContent = company.code_nace || 'N/A'

    // Adresse
    const addressDiv = document.getElementById('company-address')
    if (company.adresse) {
      addressDiv.innerHTML = `
        ${company.adresse.rue || ''}<br>
        ${company.adresse.code_postal || ''} ${company.adresse.commune || ''}
      `
    }

    // Statut avec badge coloré
    const statusSpan = document.getElementById('company-status')
    statusSpan.textContent = company.statut || 'Inconnu'
    statusSpan.className = `badge ${this.getStatusBadgeClass(company.statut)}`

    // Analyse automatique
    this.generateAutoAnalysis(company)

    // Afficher la section
    this.companyInfoTarget.style.display = 'block'
  }

  generateAutoAnalysis(company) {
    const analysisContent = document.getElementById('auto-analysis-content')

    let analysis = []

    // Analyse du statut
    if (company.statut === 'ACTIF') {
      analysis.push('✅ Entreprise active et éligible aux aides')
    } else {
      analysis.push('⚠️ Vérifier le statut de l\'entreprise')
    }

    // Analyse du code NACE
    if (company.code_nace) {
      const naceAnalysis = this.analyzeNACE(company.code_nace)
      analysis.push(`🏢 Secteur: ${naceAnalysis}`)
    }

    // Analyse de la taille (si disponible)
    if (company.taille_entreprise) {
      analysis.push(`📊 Taille: ${company.taille_entreprise}`)
    }

    analysisContent.innerHTML = analysis.map(item => `<div>${item}</div>`).join('')
  }

  analyzeNACE(codeNace) {
    // Mapping simplifié des codes NACE
    const naceMapping = {
      '46': 'Commerce de gros',
      '47': 'Commerce de détail',
      '62': 'Services informatiques',
      '70': 'Conseil en gestion',
      '71': 'Architecture et ingénierie',
      '74': 'Autres services professionnels',
      '10': 'Industries alimentaires',
      '25': 'Fabrication de produits métalliques'
    }

    const prefix = codeNace.substring(0, 2)
    return naceMapping[prefix] || 'Secteur d\'activité identifié'
  }

  getStatusBadgeClass(statut) {
    switch(statut) {
      case 'ACTIF':
        return 'bg-success'
      case 'CESSATION':
        return 'bg-danger'
      case 'SUSPENSION':
        return 'bg-warning'
      default:
        return 'bg-secondary'
    }
  }

  isValidBCE(bceNumber) {
    // Format belge: 0123.456.789 ou 0123456789
    const regex = /^\d{4}[\.\s]?\d{3}[\.\s]?\d{3}$/
    return regex.test(bceNumber.replace(/\s/g, ''))
  }

  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.style.display = 'block'
    }
    if (this.hasSearchButtonTarget) {
      this.searchButtonTarget.disabled = true
    }
  }

  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.style.display = 'none'
    }
    if (this.hasSearchButtonTarget) {
      this.searchButtonTarget.disabled = false
    }
  }

  showError(message) {
    // Créer ou mettre à jour le message d'erreur
    let errorDiv = this.element.querySelector('.error-message')
    if (!errorDiv) {
      errorDiv = document.createElement('div')
      errorDiv.className = 'alert alert-danger error-message mt-2'
      this.element.appendChild(errorDiv)
    }
    errorDiv.textContent = message

    // Masquer après 5 secondes
    setTimeout(() => {
      if (errorDiv.parentNode) {
        errorDiv.remove()
      }
    }, 5000)
  }

  enableNextStep() {
    const nextButton = this.element.querySelector('[data-action*="nextStep"]')
    if (nextButton) {
      nextButton.disabled = false
      nextButton.classList.remove('btn-outline-primary')
      nextButton.classList.add('btn-primary')
    }
  }

  nextStep() {
    console.log("Enhanced BCE Search: nextStep called")
    // Trouver le contrôleur workflow parent et déclencher la transition
    const workflowElement = this.element.closest('[data-controller*="workflow"]')
    console.log("Workflow element found:", workflowElement)
    if (workflowElement) {
      const workflowController = this.application.getControllerForElementAndIdentifier(workflowElement, 'workflow')
      console.log("Workflow controller found:", workflowController)
      if (workflowController) {
        workflowController.nextStep()

        // Transmettre les données de l'entreprise au contrôleur d'éligibilité
        this.transferCompanyDataToEligibilityChecker()
      }
    }

    // Fallback : émettre l'événement
    this.dispatch("stepComplete", {
      detail: {
        company: this.currentCompanyValue,
        nextStep: 2
      }
    })
  }

  transferCompanyDataToEligibilityChecker() {
    // Trouver l'élément de l'étape d'éligibilité
    const eligibilityElement = document.querySelector('[data-controller*="eligibility-checker"]')
    console.log("Eligibility element found:", eligibilityElement)

    if (eligibilityElement && this.currentCompanyValue) {
      const eligibilityController = this.application.getControllerForElementAndIdentifier(eligibilityElement, 'eligibility-checker')
      console.log("Eligibility controller found:", eligibilityController)

      if (eligibilityController) {
        // Utiliser la nouvelle méthode startAnalysis
        eligibilityController.startAnalysis(this.currentCompanyValue)
      } else {
        console.error("Eligibility controller not found")
      }
    } else {
      console.error("Eligibility element or company data not found", {
        element: !!eligibilityElement,
        company: !!this.currentCompanyValue
      })
    }
  }
}
