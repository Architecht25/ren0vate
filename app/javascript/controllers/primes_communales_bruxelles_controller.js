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
    apiBaseUrl: { type: String, default: "/api/primes_communales_bruxelles" }
  }

  connect() {
    console.log("🔌 Contrôleur primes communales Bruxelles connecté")
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

    console.log("🔍 Vérification primes Bruxelles pour:", codePostal)

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

    // Vérification rapide si c'est un code postal bruxellois
    if (!this.isBrusselsPostalCode(codePostal)) {
      this.showError("Ce code postal ne correspond pas à Bruxelles", ["Codes postaux valides: 1000-1210"])
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

      console.log("📡 Appel API Bruxelles pour:", codePostal)

      const response = await fetch(`${this.apiBaseUrlValue}?code_postal=${codePostal}`, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        }
      })

      const data = await response.json()

      console.log("📦 Réponse API Bruxelles:", data)

      if (data.success && data.data) {
        this.communeData = data.data
        this.showSuccess()
        this.populatePrimesSelect()
      } else {
        const errorMessage = data.error?.message || "Aucune prime trouvée pour ce code postal"
        this.showError(errorMessage, data.error?.suggestions)
      }

    } catch (error) {
      console.error("❌ Erreur API primes Bruxelles:", error)
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
      console.log("✅ Prime Bruxelles sélectionnée:", this.selectedPrime.nom)
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
      console.log("🧮 Calcul prime Bruxelles:", {
        prime: this.selectedPrime.nom,
        montant: montantTravaux
      })

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
          parametres: {}
        })
      })

      const data = await response.json()

      console.log("💰 Résultat calcul Bruxelles:", data)

      if (data.success && data.data) {
        this.displayResult(data.data.calcul)
      } else {
        console.error("Erreur calcul:", data.error)
        this.hideResultSection()
      }

    } catch (error) {
      console.error("❌ Erreur calcul prime Bruxelles:", error)
      this.hideResultSection()
    }
  }

  // === Méthodes UI ===

  resetUI() {
    this.hideLoading()
    this.hideStatus()
    this.hidePrimesSelection()
    this.hideMontantSection()
    this.hideResultSection()
  }

  showLoading() {
    this.loadingTarget.style.display = 'block'
    this.hideStatus()
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

  showError(message, suggestions = []) {
    this.showStatus()
    this.statusIconTarget.className = 'bi bi-exclamation-circle-fill text-danger'
    this.statusTextTarget.textContent = message
    this.statusTextTarget.className = 'fw-bold text-danger'

    // Afficher les suggestions si disponibles
    if (suggestions && suggestions.length > 0) {
      const suggestionsText = suggestions.join(', ')
      this.statusTextTarget.textContent += ` (${suggestionsText})`
    }
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

  showResultSection() {
    this.resultSectionTarget.style.display = 'block'
  }

  hideResultSection() {
    this.resultSectionTarget.style.display = 'none'
  }

  populatePrimesSelect() {
    // Vider la liste
    this.primeSelectTarget.innerHTML = '<option value="">Choisir une prime...</option>'

    // Ajouter les primes disponibles
    this.communeData.primes.forEach(prime => {
      const option = document.createElement('option')
      option.value = prime.id
      option.textContent = `${prime.nom} (${prime.description})`
      this.primeSelectTarget.appendChild(option)
    })

    this.showPrimesSelection()
  }

  displayResult(calcul) {
    // Formater le montant
    const montantFormate = new Intl.NumberFormat('fr-BE', {
      style: 'currency',
      currency: 'EUR',
      minimumFractionDigits: 2
    }).format(calcul.montant_prime)

    // Afficher le résultat
    this.resultTarget.textContent = montantFormate

    // Afficher les détails
    if (this.hasDetailsTarget) {
      this.detailsTarget.textContent = calcul.details || ''
    }

    this.showResultSection()

    // Notifier les autres composants
    this.updateGlobalTotal()
  }

  // Vérification si c'est un code postal bruxellois
  isBrusselsPostalCode(codePostal) {
    const brusselsPostalCodes = [
      '1000', '1020', '1030', '1040', '1050', '1060', '1070', '1080',
      '1081', '1082', '1083', '1090', '1120', '1130', '1140', '1150',
      '1160', '1170', '1180', '1190', '1200', '1210'
    ]
    return brusselsPostalCodes.includes(codePostal)
  }

  // Intégration avec le système global
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
