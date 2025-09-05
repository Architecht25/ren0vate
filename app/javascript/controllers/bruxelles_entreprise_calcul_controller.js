import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "sectionTitle", "tailleEntreprise", "ageEntreprise", "categorieEntreprise",
    "totalGeneral", "totalTransition", "totalInvestissements", "totalRH", "totalServices"
  ]

  connect() {
    console.log("🏢 Contrôleur Bruxelles Entreprises connecté")

    // Charger les données d'aides depuis le script JSON
    this.loadAidesData()

    // Configuration de l'auto-save
    this.simulationId = this.getSimulationId()
    this.setupAutoSave()

    // Initialiser les calculs
    this.updateCalculations()
  }

  disconnect() {
    if (this.autoSaveTimeout) {
      clearTimeout(this.autoSaveTimeout)
    }
  }

  loadAidesData() {
    const dataScript = document.getElementById('bruxelles-entreprise-data')
    if (dataScript) {
      try {
        this.aidesData = JSON.parse(dataScript.textContent)
        console.log("🎯 Données aides entreprises chargées:", Object.keys(this.aidesData))
      } catch (e) {
        console.error("❌ Erreur parsing données aides:", e)
        this.aidesData = {}
      }
    } else {
      console.warn("⚠️ Script de données aides non trouvé")
      this.aidesData = {}
    }
  }

  getSimulationId() {
    // Méthode 1: Depuis l'URL
    const pathParts = window.location.pathname.split('/')
    const simulationIndex = pathParts.indexOf('simulations')
    if (simulationIndex !== -1 && pathParts[simulationIndex + 1]) {
      return pathParts[simulationIndex + 1]
    }
    return null
  }

  setupAutoSave() {
    // Écouter les changements sur les selects et inputs
    this.element.addEventListener('change', (event) => {
      if (event.target.matches('select, input')) {
        console.log("🔄 Changement détecté entreprise:", event.target.name || event.target.id, event.target.value)
        this.updateCalculations()
        this.debouncedAutoSave()
      }
    })

    this.element.addEventListener('input', (event) => {
      if (event.target.matches('input[type="number"]')) {
        console.log("📝 Saisie montant entreprise:", event.target.name || event.target.id, event.target.value)
        this.updateCalculations()
        this.debouncedAutoSave()
      }
    })
  }

  // Méthodes appelées par les changements dans le template
  tailleEntrepriseChanged() {
    console.log("📊 Taille entreprise changée:", this.tailleEntrepriseTarget.value)
    this.updateCalculations()
    this.debouncedAutoSave()
  }

  ageEntrepriseChanged() {
    console.log("📅 Âge entreprise changé:", this.ageEntrepriseTarget.value)
    this.updateCalculations()
    this.debouncedAutoSave()
  }

  updateCalculations() {
    // Récupérer les paramètres de l'entreprise
    const taille = this.hasTailleEntrepriseTarget ? this.tailleEntrepriseTarget.value : ''
    const age = this.hasAgeEntrepriseTarget ? this.ageEntrepriseTarget.value : ''

    console.log("🧮 Mise à jour calculs entreprise:", { taille, age })

    // Mettre à jour l'affichage de la catégorie
    if (this.hasCategorieEntrepriseTarget) {
      let categorieText = "Type d'entreprise"
      if (taille) {
        categorieText = taille.toUpperCase()
        if (age) {
          categorieText += ` (${age})`
        }
      }
      this.categorieEntrepriseTarget.textContent = categorieText
    }

    // Calculer les totaux par catégorie
    let totalTransition = 0
    let totalInvestissements = 0
    let totalRH = 0
    let totalServices = 0

    // Parcourir toutes les cartes d'aides et calculer les montants
    this.element.querySelectorAll('[data-aide-card]').forEach(card => {
      const montantInput = card.querySelector('input[type="number"]')
      if (montantInput && montantInput.value) {
        const montant = parseFloat(montantInput.value) || 0
        const categorie = card.dataset.aideCard

        // Calculer l'aide selon les paramètres de l'entreprise
        const aideCalculee = this.calculateAide(montant, categorie, taille, age)

        // Additionner selon la catégorie
        switch (categorie) {
          case 'transition_energetique':
            totalTransition += aideCalculee
            break
          case 'investissements':
            totalInvestissements += aideCalculee
            break
          case 'ressources_humaines':
            totalRH += aideCalculee
            break
          case 'services':
            totalServices += aideCalculee
            break
        }
      }
    })

    // Mettre à jour l'affichage
    this.updateDisplayTotals(totalTransition, totalInvestissements, totalRH, totalServices)
  }

  calculateAide(montantInvesti, categorie, tailleEntreprise, ageEntreprise) {
    // Récupérer les données de la catégorie
    const aides = this.aidesData[categorie] || {}

    // Logique de base : 25% du montant investi
    let taux = 25.0
    let plafond = 10000

    // Ajustements selon la taille
    switch (tailleEntreprise) {
      case 'tpe':
        taux = 40.0
        plafond = 15000
        break
      case 'pme':
        taux = 30.0
        plafond = 12000
        break
      case 'moyenne':
        taux = 25.0
        plafond = 10000
        break
    }

    // Majoration pour jeunes entreprises
    if (ageEntreprise === 'moins_3_ans') {
      taux += 10
    }

    // Calculer l'aide
    const aideCalculee = Math.min(montantInvesti * (taux / 100), plafond)

    return Math.round(aideCalculee)
  }

  updateDisplayTotals(totalTransition, totalInvestissements, totalRH, totalServices) {
    const totalGeneral = totalTransition + totalInvestissements + totalRH + totalServices

    if (this.hasTotalGeneralTarget) {
      this.totalGeneralTarget.textContent = this.formatMontant(totalGeneral)
    }
    if (this.hasTotalTransitionTarget) {
      this.totalTransitionTarget.textContent = this.formatMontant(totalTransition)
    }
    if (this.hasTotalInvestissementsTarget) {
      this.totalInvestissementsTarget.textContent = this.formatMontant(totalInvestissements)
    }
    if (this.hasTotalRHTarget) {
      this.totalRHTarget.textContent = this.formatMontant(totalRH)
    }
    if (this.hasTotalServicesTarget) {
      this.totalServicesTarget.textContent = this.formatMontant(totalServices)
    }

    console.log("💰 Totaux mis à jour:", {
      totalGeneral,
      totalTransition,
      totalInvestissements,
      totalRH,
      totalServices
    })
  }

  formatMontant(montant) {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'EUR',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(montant)
  }

  // Auto-save avec débounce
  debouncedAutoSave() {
    if (this.autoSaveTimeout) {
      clearTimeout(this.autoSaveTimeout)
    }
    this.autoSaveTimeout = setTimeout(() => {
      this.autoSave()
    }, 1000)
  }

  autoSave() {
    if (!this.simulationId) {
      console.log("⚠️ Pas d'ID de simulation pour auto-save entreprise")
      return
    }

    // Vérifier si la restauration est en cours
    if (window.isRestoringValues) {
      console.log('🔄 Sauvegarde entreprise ignorée: restauration en cours')
      return
    }

    // Collecter toutes les données du formulaire
    const userInputs = this.collectFormData()

    if (Object.keys(userInputs).length === 0) {
      console.log("📝 Aucune donnée entreprise à sauvegarder")
      return
    }

    console.log('💾 Sauvegarde données entreprise:', Object.keys(userInputs).length, 'champs')

    fetch(`/fr/simulations/${this.simulationId}/update_prime_inputs`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json'
      },
      body: JSON.stringify({ user_inputs: userInputs })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        console.log("✅ Auto-save entreprise réussi:", data.total_amount, "€")
        this.showSaveIndicator('success')
      } else {
        console.error("❌ Erreur auto-save entreprise:", data.error)
        this.showSaveIndicator('error')
      }
    })
    .catch(error => {
      console.error("❌ Erreur réseau auto-save entreprise:", error)
      this.showSaveIndicator('error')
    })
  }

  collectFormData() {
    const userInputs = {}

    // Paramètres de l'entreprise
    if (this.hasTailleEntrepriseTarget && this.tailleEntrepriseTarget.value) {
      userInputs['entreprise_taille'] = this.tailleEntrepriseTarget.value
    }
    if (this.hasAgeEntrepriseTarget && this.ageEntrepriseTarget.value) {
      userInputs['entreprise_age'] = this.ageEntrepriseTarget.value
    }

    // Tous les inputs avec data-slug
    this.element.querySelectorAll('input[data-slug], select[data-slug]').forEach(input => {
      if (input.value && input.value !== '0' && input.value !== '') {
        userInputs[input.dataset.slug] = input.value
      }
    })

    // Montants investis dans les cartes d'aides (fallback)
    this.element.querySelectorAll('[data-aide-card] input[type="number"]').forEach(input => {
      if (input.value && input.value !== '0') {
        const card = input.closest('[data-aide-card]')
        const categorie = card?.dataset.aideCard
        const aideId = input.name || input.id

        if (categorie && aideId && !input.dataset.slug) {
          userInputs[`${categorie}_${aideId}`] = input.value
        }
      }
    })

    return userInputs
  }

  showSaveIndicator(status) {
    // Créer ou mettre à jour l'indicateur de sauvegarde
    let indicator = document.getElementById('save-indicator-entreprise')
    if (!indicator) {
      indicator = document.createElement('div')
      indicator.id = 'save-indicator-entreprise'
      document.body.appendChild(indicator)
    }

    indicator.className = `position-fixed top-0 end-0 m-3 alert alert-${status === 'success' ? 'success' : 'danger'} alert-dismissible fade show`
    indicator.style.zIndex = '9999'
    indicator.innerHTML = `
      <i class="bi bi-${status === 'success' ? 'check-circle' : 'exclamation-triangle'} me-2"></i>
      ${status === 'success' ? 'Données entreprise sauvegardées' : 'Erreur sauvegarde entreprise'}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `

    // Masquer automatiquement après 3 secondes
    setTimeout(() => {
      if (indicator.parentNode) {
        indicator.remove()
      }
    }, 3000)
  }
}
