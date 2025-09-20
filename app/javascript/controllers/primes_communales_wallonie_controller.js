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
    apiBaseUrl: { type: String, default: "/api/primes_communales_wallonie" }
  }

  connect() {
    console.log("🔌 Contrôleur primes communales Wallonie connecté")
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

    console.log("🔍 Vérification primes Wallonie pour:", codePostal)

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

    // Vérification rapide si c'est un code postal wallon
    if (!this.isWalloonPostalCode(codePostal)) {
      this.showError("Ce code postal ne correspond pas à la Wallonie", [
        "Codes postaux valides: 4000-4999, 5000-5999, 6000-6999, 7000-7999, 1300-1399"
      ])
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

      console.log("📡 Appel API Wallonie pour:", codePostal)

      const response = await fetch(`${this.apiBaseUrlValue}?code_postal=${codePostal}`, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        }
      })

      const data = await response.json()

      console.log("📦 Réponse API Wallonie:", data)

      if (data.success && data.data) {
        this.communeData = data.data
        this.showSuccess()
        this.populatePrimesSelect()
      } else {
        const errorMessage = data.error?.message || "Aucune prime trouvée pour ce code postal"
        this.showError(errorMessage, data.error?.suggestions)
      }

    } catch (error) {
      console.error("❌ Erreur API primes Wallonie:", error)
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
      console.log("✅ Prime Wallonie sélectionnée:", this.selectedPrime.nom)
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
      console.log("🧮 Calcul prime Wallonie:", {
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
          code_postal: this.codePostalTarget.value.trim(),
          prime_id: this.selectedPrime.id,
          montant_travaux: montantTravaux,
          parametres: {}
        })
      })

      const data = await response.json()

      console.log("💰 Résultat calcul Wallonie:", data)

      if (data.success && data.data.calcul) {
        this.displayResult(data.data.calcul)
      } else {
        this.showError(data.error?.message || "Erreur lors du calcul")
      }

    } catch (error) {
      console.error("❌ Erreur calcul prime Wallonie:", error)
      this.showError("Erreur lors du calcul. Veuillez réessayer.")
    }
  }

  // === MÉTHODES D'AFFICHAGE ===

  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.style.display = 'block'
    }
  }

  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.style.display = 'none'
    }
  }

  showSuccess() {
    if (this.hasStatusTarget) {
      this.statusTarget.className = 'status success'
      this.statusTarget.style.display = 'block'
    }

    if (this.hasStatusIconTarget) {
      this.statusIconTarget.textContent = '✅'
    }

    if (this.hasStatusTextTarget) {
      const commune = this.communeData?.commune || 'commune'
      const nombrePrimes = this.communeData?.nombre_primes || 0
      this.statusTextTarget.textContent = `${nombrePrimes} prime${nombrePrimes > 1 ? 's' : ''} disponible${nombrePrimes > 1 ? 's' : ''} à ${commune}`
    }
  }

  showError(message, suggestions = []) {
    if (this.hasStatusTarget) {
      this.statusTarget.className = 'status error'
      this.statusTarget.style.display = 'block'
    }

    if (this.hasStatusIconTarget) {
      this.statusIconTarget.textContent = '❌'
    }

    if (this.hasStatusTextTarget) {
      let errorText = message
      if (suggestions.length > 0) {
        errorText += `. Suggestions: ${suggestions.join(', ')}`
      }
      this.statusTextTarget.textContent = errorText
    }
  }

  showPrimesSelection() {
    if (this.hasPrimesSelectionTarget) {
      this.primesSelectionTarget.style.display = 'block'
    }
  }

  showMontantSection() {
    if (this.hasMontantSectionTarget) {
      this.montantSectionTarget.style.display = 'block'
    }
  }

  hideMontantSection() {
    if (this.hasMontantSectionTarget) {
      this.montantSectionTarget.style.display = 'none'
    }
  }

  showResultSection() {
    if (this.hasResultSectionTarget) {
      this.resultSectionTarget.style.display = 'block'
    }
  }

  hideResultSection() {
    if (this.hasResultSectionTarget) {
      this.resultSectionTarget.style.display = 'none'
    }
  }

  resetUI() {
    this.hideLoading()

    if (this.hasStatusTarget) {
      this.statusTarget.style.display = 'none'
    }

    if (this.hasPrimesSelectionTarget) {
      this.primesSelectionTarget.style.display = 'none'
    }

    this.hideMontantSection()
    this.hideResultSection()

    this.selectedPrime = null
    this.communeData = null
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

  // Vérification si c'est un code postal wallon
  isWalloonPostalCode(codePostal) {
    const code = parseInt(codePostal, 10)

    // Codes postaux wallons selon les intervalles principaux
    return (code >= 4000 && code <= 4999) ||  // Province de Liège
           (code >= 5000 && code <= 5999) ||  // Province de Namur
           (code >= 6000 && code <= 6999) ||  // Province de Hainaut
           (code >= 7000 && code <= 7999) ||  // Province de Hainaut (Mons, Tournai)
           (code >= 1300 && code <= 1399)     // Brabant wallon
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
