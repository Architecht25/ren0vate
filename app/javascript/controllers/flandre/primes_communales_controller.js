import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "codePostal",
    "loading",
    "status",
    "statusIcon",
    "statusText",
    "primesSelection",
    "primeSelect",
    "montantSection",
    "montantInput",
    "resultSection",
    "result",
    "details"
  ]

  static values = {
    debounceDelay: { type: Number, default: 800 },
    apiBaseUrl: { type: String, default: "/api/primes_communales" }
  }

  connect() {
    this.debounceTimer = null
    this.selectedPrime = null
    this.communeData = null
  }

  disconnect() {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }
  }

  // Événement : saisie du code postal
  checkPrimes() {
    const codePostal = this.codePostalTarget.value.trim()


    // Reset des états
    this.resetUI()

    // Validation basique
    if (!codePostal) {
      return
    }

    if (!/^\d{4}$/.test(codePostal)) {
      this.showError("Code postal invalide (4 chiffres requis)")
      return
    }

    // Debounce pour éviter trop d'appels API
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => {
      this.searchPrimes(codePostal)
    }, this.debounceDelayValue)
  }

  // Recherche des primes via API
  async searchPrimes(codePostal) {
    try {
      this.showLoading()


      const response = await fetch(`${this.apiBaseUrlValue}?code_postal=${codePostal}`, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        }
      })

      const data = await response.json()


      if (data.success && data.data) {
        this.communeData = data.data
        this.showSuccess()
        this.populatePrimesSelect()
      } else {
        const errorMessage = data.error?.message || "Aucune prime trouvée pour ce code postal"
        this.showError(errorMessage, data.error?.suggestions)
      }

    } catch (error) {
      this.showError("Erreur de connexion. Veuillez réessayer.")
    } finally {
      this.hideLoading()
    }
  }

  // Sélection d'une prime
  selectPrime() {
    const selectedValue = this.primeSelectTarget.value

    if (!selectedValue) {
      this.selectedPrime = null
      this.hideMontantSection()
      this.hideResultSection()
      return
    }

    // Trouver la prime sélectionnée
    this.selectedPrime = this.communeData.primes.find(p => p.id === selectedValue)

    if (this.selectedPrime) {
      this.showMontantSection()

      // Calculer automatiquement si un montant est déjà saisi
      if (this.montantInputTarget.value) {
        this.calculatePrime()
      }
    }
  }

  // Calcul du montant de la prime
  async calculatePrime() {
    if (!this.selectedPrime) return

    const montantTravaux = parseFloat(this.montantInputTarget.value) || 0

    if (montantTravaux <= 0) {
      this.hideResultSection()
      return
    }

    try {
      const response = await fetch(`${this.apiBaseUrlValue}/calculate`, {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({
          code_postal: this.communeData.code_postal,
          prime_id: this.selectedPrime.id,
          montant_travaux: montantTravaux,
          parametres: this.getCalculationParameters()
        })
      })

      const data = await response.json()

      if (data.success && data.data) {
        this.showResult(data.data.calcul)
      } else {
        this.hideResultSection()
      }

    } catch (error) {
      this.hideResultSection()
    }
  }

  // Paramètres spéciaux pour certains types de calcul
  getCalculationParameters() {
    const params = {}

    // Pour les panneaux solaires (par_kw)
    if (this.selectedPrime?.type_calcul === 'par_kw') {
      // Estimation basique : 1 kW pour 1000€ de travaux
      params.puissance_kw = Math.max(1, Math.floor(parseFloat(this.montantInputTarget.value) / 1000))
    }

    // Pour les toitures vertes (par_m2)
    if (this.selectedPrime?.type_calcul === 'par_m2') {
      // Estimation basique : 1 m² pour 100€ de travaux
      params.surface_m2 = Math.max(1, Math.floor(parseFloat(this.montantInputTarget.value) / 100))
    }

    return params
  }

  // Interface utilisateur
  resetUI() {
    this.hideLoading()
    this.hideStatus()
    this.hidePrimesSelection()
    this.hideMontantSection()
    this.hideResultSection()
    this.selectedPrime = null
    this.communeData = null
  }

  showLoading() {
    this.loadingTarget.style.display = 'block'
  }

  hideLoading() {
    this.loadingTarget.style.display = 'none'
  }

  showStatus() {
    this.statusTarget.style.display = 'block'
  }

  hideStatus() {
    this.statusTarget.style.display = 'none'
  }

  showSuccess() {
    this.showStatus()
    this.statusIconTarget.className = 'bi bi-check-circle-fill text-success'
    this.statusTextTarget.textContent = `${this.communeData.commune} : ${this.communeData.nombre_primes} prime(s) disponible(s)`
    this.statusTextTarget.className = 'fw-bold text-success'
  }

  showError(message, suggestions = null) {
    this.showStatus()
    this.statusIconTarget.className = 'bi bi-exclamation-triangle-fill text-warning'
    this.statusTextTarget.textContent = message
    this.statusTextTarget.className = 'fw-bold text-warning'

    if (suggestions && suggestions.length > 0) {
      this.statusTextTarget.textContent += ` Suggestions: ${suggestions.slice(0, 2).join(', ')}`
    }
  }

  populatePrimesSelect() {
    this.primeSelectTarget.innerHTML = '<option value="">Choisir une prime...</option>'

    this.communeData.primes.forEach(prime => {
      const option = document.createElement('option')
      option.value = prime.id
      option.textContent = `${prime.nom} - ${prime.description}`
      this.primeSelectTarget.appendChild(option)
    })

    this.showPrimesSelection()
  }

  showPrimesSelection() {
    this.primesSelectionTarget.style.display = 'block'
  }

  hidePrimesSelection() {
    this.primesSelectionTarget.style.display = 'none'
  }

  showMontantSection() {
    this.montantSectionTarget.style.display = 'block'
  }

  hideMontantSection() {
    this.montantSectionTarget.style.display = 'none'
  }

  showResult(calcul) {
    this.resultTarget.textContent = `${calcul.montant_prime.toFixed(2)} €`
    this.detailsTarget.textContent = calcul.details_calcul

    // Style selon le montant
    if (calcul.montant_prime > 0) {
      this.resultTarget.classList.add('text-success')
      this.resultTarget.classList.remove('text-muted')
    } else {
      this.resultTarget.classList.remove('text-success')
      this.resultTarget.classList.add('text-muted')
    }

    this.showResultSection()
    this.updateGlobalTotal()
  }

  showResultSection() {
    this.resultSectionTarget.style.display = 'block'
  }

  hideResultSection() {
    this.resultSectionTarget.style.display = 'none'
  }

  // Mise à jour du total global (intégration avec le système existant)
  updateGlobalTotal() {
    // Rechercher le contrôleur PEB existant
    const pebController = document.querySelector('[data-controller="peb"]')
    if (pebController && window.Stimulus) {
      const controller = window.Stimulus.getControllerForElementAndIdentifier(pebController, 'peb')
      if (controller && controller.mettreAJourTotalPrimes) {
        controller.mettreAJourTotalPrimes()
      }
    }
  }

  // Getters pour la compatibilité avec le système existant
  get montantPrimeCommunale() {
    const resultText = this.hasResultTarget ? this.resultTarget.textContent : '0 €'
    return parseFloat(resultText.replace(/[^\d.,]/g, '').replace(',', '.')) || 0
  }

  get hasPrimeCalculated() {
    return this.selectedPrime && this.hasResultTarget && this.resultSectionTarget.style.display !== 'none'
  }

  // Méthode utilitaire pour obtenir le token CSRF
  getCSRFToken() {
    const token = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
    return token || ''
  }
}
