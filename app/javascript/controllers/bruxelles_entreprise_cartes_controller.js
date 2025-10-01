import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "totalTransition", "totalInvestissements", "totalRH", "totalServices",
    "totalGeneral", "tailleEntreprise", "ageEntreprise"
  ]

  connect() {
    console.log("🏢 Contrôleur coordinateur Bruxelles Entreprise Cartes connecté")

    // Initialiser les totaux
    this.totauxParCategorie = {
      transition_energetique: 0,
      investissements: 0,
      recrutement_formation: 0,
      services_professionnels: 0
    }

    // Écouter les événements des cartes individuelles
    this.setupEventListeners()

    // Écouter les changements des paramètres d'entreprise
    this.setupParameterListeners()

    // Mettre à jour les placeholders adaptatifs dès la connexion
    this.updateAdaptivePlaceholders()
  }

  setupEventListeners() {
    // Écouter les événements de calcul des cartes
    this.element.addEventListener('bruxelles-entreprise-card:totalCalculated', (event) => {
      this.handleCategoryTotalUpdate(event.detail)
    })

    this.element.addEventListener('bruxelles-entreprise-card:primeCalculated', (event) => {
      this.handlePrimeCalculated(event.detail)
    })
  }

  setupParameterListeners() {
    // Écouter les changements de taille d'entreprise
    if (this.hasTailleEntrepriseTarget) {
      this.tailleEntrepriseTarget.addEventListener('change', () => {
        this.recalculateAllCards()
      })
    }

    // Écouter les changements d'âge d'entreprise
    if (this.hasAgeEntrepriseTarget) {
      this.ageEntrepriseTarget.addEventListener('change', () => {
        this.recalculateAllCards()
      })
    }
  }

  handleCategoryTotalUpdate(detail) {
    const { categorie, total } = detail
    console.log(`📊 Mise à jour total catégorie ${categorie}:`, total)

    // Mettre à jour le total de la catégorie
    this.totauxParCategorie[categorie] = total

    // Mettre à jour l'affichage du total pour cette catégorie
    this.updateCategoryDisplay(categorie, total)

    // Recalculer le total général
    this.updateTotalGeneral()
  }

  handlePrimeCalculated(detail) {
    const { slug, montantInvesti, montantPrime, categorie } = detail
    console.log(`💰 Prime calculée ${slug}:`, { montantInvesti, montantPrime, categorie })

    // Optionnel: sauvegarder automatiquement
    this.debouncedAutoSave()
  }

  updateCategoryDisplay(categorie, total) {
    const targetMap = {
      'transition_energetique': 'totalTransition',
      'investissements': 'totalInvestissements',
      'recrutement_formation': 'totalRH',
      'services_professionnels': 'totalServices'
    }

    const targetName = targetMap[categorie]
    if (targetName && this[`has${targetName.charAt(0).toUpperCase() + targetName.slice(1)}Target`]) {
      const target = this[`${targetName}Target`]
      target.textContent = this.formatMontant(total)

      // Animation pour indiquer le changement
      target.classList.add('text-success')
      setTimeout(() => {
        target.classList.remove('text-success')
      }, 1000)
    }
  }

  updateTotalGeneral() {
    const totalGeneral = Object.values(this.totauxParCategorie).reduce((sum, val) => sum + val, 0)
    console.log("📈 Total général mis à jour:", totalGeneral)

    if (this.hasTotalGeneralTarget) {
      this.totalGeneralTarget.textContent = this.formatMontant(totalGeneral)

      // Animation et style selon le montant
      this.totalGeneralTarget.classList.remove('text-success', 'text-warning', 'text-danger')
      if (totalGeneral > 50000) {
        this.totalGeneralTarget.classList.add('text-success')
      } else if (totalGeneral > 10000) {
        this.totalGeneralTarget.classList.add('text-warning')
      } else if (totalGeneral > 0) {
        this.totalGeneralTarget.classList.add('text-info')
      }
    }

    // Afficher/masquer le résumé global selon le montant
    this.toggleGlobalSummary(totalGeneral > 0)

    // Déclencher l'événement de mise à jour des économies
    this.dispatchSavingsUpdateEvent({
      total_amount: totalGeneral,
      savings_data: null // sera calculé côté serveur
    });
  }

  toggleGlobalSummary(show) {
    const summaryElement = document.querySelector('#global-summary, [data-target="globalSummary"]')
    if (summaryElement) {
      summaryElement.style.display = show ? 'block' : 'none'
    }
  }

  recalculateAllCards() {
    console.log("🔄 Recalcul de toutes les cartes suite au changement de paramètres")

    // Mettre à jour les placeholders adaptatifs
    this.updateAdaptivePlaceholders()

    // Déclencher un recalcul sur toutes les cartes
    const cards = this.element.querySelectorAll('[data-controller*="bruxelles-entreprise-card"]')
    cards.forEach(card => {
      const controller = this.application.getControllerForElementAndIdentifier(card, 'bruxelles-entreprise-card')
      if (controller && controller.calculateTotals) {
        // Recalculer tous les inputs de cette carte
        const inputs = card.querySelectorAll('input[type="number"]')
        inputs.forEach(input => {
          if (input.value) {
            controller.handleInputChange(input)
          }
        })
      }
    })
  }

  updateAdaptivePlaceholders() {
    const tailleEntreprise = this.hasTailleEntrepriseTarget ? this.tailleEntrepriseTarget.value : null
    const ageEntreprise = this.hasAgeEntrepriseTarget ? this.ageEntrepriseTarget.value : null

    console.log("🏷️ Mise à jour placeholders adaptatifs:", { tailleEntreprise, ageEntreprise })

    // Mettre à jour le placeholder pour la Prime Matériel ou Travaux
    const materielTravauxInput = this.element.querySelector('input[data-bruxelles-entreprise-card-slug="bruxelles_prime_materiel_travaux"]')
    if (materielTravauxInput) {
      const montantMin = this.calculateMinimumForMaterielTravaux(tailleEntreprise, ageEntreprise)
      materielTravauxInput.placeholder = `${montantMin.toLocaleString('fr-FR')}€ min`
      console.log("📝 Placeholder mis à jour pour Prime Matériel/Travaux:", `${montantMin.toLocaleString('fr-FR')}€ min`)
    }

    // Mettre à jour les autres placeholders avec montants fixes
    this.updateStaticPlaceholders()
  }

  updateStaticPlaceholders() {
    const staticPlaceholders = {
      'bruxelles_prime_immobilier': '100.000€ min',
      'bruxelles_prime_conformite_normes': '5.000€ min',
      'bruxelles_prime_securisation': '2.000€ min',
      'bruxelles_prime_accessibilite': '1.000€ min',
      'bruxelles_investissements_transition_economique': '2.000€ min',
      'bruxelles_mobilite_velo_cargo': '500€ min',
      'bruxelles_prime_consultance': '500€ min',
      'bruxelles_prime_digitalisation': '500€ min'
    }

    Object.entries(staticPlaceholders).forEach(([slug, placeholder]) => {
      const input = this.element.querySelector(`input[data-bruxelles-entreprise-card-slug="${slug}"]`)
      if (input) {
        input.placeholder = placeholder
        console.log(`📝 Placeholder mis à jour pour ${slug}:`, placeholder)
      }
    })
  }

  getAdaptiveMinimumAmount(aideSlug, tailleEntreprise, ageEntreprise) {
    switch (aideSlug) {
      case 'bruxelles_prime_materiel_travaux':
        return this.calculateMinimumForMaterielTravaux(tailleEntreprise, ageEntreprise)
      case 'bruxelles_prime_immobilier':
        return 100000
      case 'bruxelles_prime_conformite_normes':
        return 5000
      case 'bruxelles_prime_securisation':
        return 2000
      case 'bruxelles_prime_accessibilite':
        return 1000
      case 'bruxelles_investissements_transition_economique':
        return 2000
      case 'bruxelles_mobilite_velo_cargo':
        return 500
      case 'bruxelles_prime_consultance':
        return 500
      case 'bruxelles_prime_digitalisation':
        return 500
      default:
        return null // Utiliser le montant par défaut des données JSON
    }
  }

  calculateMinimumForMaterielTravaux(tailleEntreprise, ageEntreprise) {
    // Déterminer si c'est une entreprise "starter" (< 4 ans)
    const isStarter = ageEntreprise === "moins_4_ans" || ageEntreprise === "moins_3_ans"

    // Si c'est une starter, minimum 5.000€ indépendamment de la taille
    if (isStarter) {
      return 5000
    }

    // Sinon, selon la taille d'entreprise
    switch (tailleEntreprise) {
      case "tpe":
      case "micro":
        return 7500  // Micro > 4 ans
      case "pme":
      case "petite":
        return 15000 // Petite > 4 ans
      case "moyenne":
        return 50000 // Moyenne > 4 ans
      default:
        return 5000  // Valeur par défaut
    }
  }

  // Méthodes appelées depuis le template
  tailleEntrepriseChanged() {
    console.log("📊 Taille entreprise changée:", this.tailleEntrepriseTarget.value)
    this.recalculateAllCards()
    this.debouncedAutoSave()
  }

  ageEntrepriseChanged() {
    console.log("📅 Âge entreprise changé:", this.ageEntrepriseTarget.value)
    this.recalculateAllCards()
    this.debouncedAutoSave()
  }

  formatMontant(montant) {
    return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'EUR',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(montant || 0)
  }

  // Auto-save avec débounce
  debouncedAutoSave() {
    if (this.autoSaveTimeout) {
      clearTimeout(this.autoSaveTimeout)
    }
    this.autoSaveTimeout = setTimeout(() => {
      this.autoSave()
    }, 1500) // Délai plus long pour éviter trop de requêtes
  }

  autoSave() {
    const simulationId = this.getSimulationId()
    if (!simulationId) {
      console.log("⚠️ Pas d'ID de simulation pour auto-save")
      return
    }

    const userInputs = this.collectAllInputs()
    if (Object.keys(userInputs).length === 0) {
      console.log("📝 Aucune donnée à sauvegarder")
      return
    }

    console.log('💾 Auto-sauvegarde:', Object.keys(userInputs).length, 'champs')

    fetch(`/fr/simulations/${simulationId}/update_prime_inputs`, {
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
        console.log("✅ Auto-save réussi")
        this.showSaveIndicator('success')
      } else {
        console.error("❌ Erreur auto-save:", data.error)
        this.showSaveIndicator('error')
      }
    })
    .catch(error => {
      console.error("❌ Erreur réseau auto-save:", error)
      this.showSaveIndicator('error')
    })
  }

  collectAllInputs() {
    const userInputs = {}

    // Paramètres d'entreprise
    if (this.hasTailleEntrepriseTarget && this.tailleEntrepriseTarget.value) {
      userInputs['entreprise_taille'] = this.tailleEntrepriseTarget.value
    }
    if (this.hasAgeEntrepriseTarget && this.ageEntrepriseTarget.value) {
      userInputs['entreprise_age'] = this.ageEntrepriseTarget.value
    }

    // Tous les inputs des cartes
    this.element.querySelectorAll('input[type="number"][data-bruxelles-entreprise-card-slug]').forEach(input => {
      if (input.value && input.value !== '0' && input.value !== '') {
        const slug = input.dataset.bruxellesEntrepriseCardSlug
        userInputs[slug] = parseFloat(input.value)
      }
    })

    return userInputs
  }

  getSimulationId() {
    const pathParts = window.location.pathname.split('/')
    const simulationIndex = pathParts.indexOf('simulations')
    if (simulationIndex !== -1 && pathParts[simulationIndex + 1]) {
      return pathParts[simulationIndex + 1]
    }
    return null
  }

  showSaveIndicator(status) {
    let indicator = document.getElementById('save-indicator-cartes')
    if (!indicator) {
      indicator = document.createElement('div')
      indicator.id = 'save-indicator-cartes'
      document.body.appendChild(indicator)
    }

    indicator.className = `position-fixed top-0 end-0 m-3 alert alert-${status === 'success' ? 'success' : 'danger'} alert-dismissible fade show`
    indicator.style.zIndex = '9999'
    indicator.innerHTML = `
      <i class="bi bi-${status === 'success' ? 'check-circle' : 'exclamation-triangle'} me-2"></i>
      ${status === 'success' ? 'Simulation sauvegardée' : 'Erreur sauvegarde'}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `

    setTimeout(() => {
      if (indicator.parentNode) {
        indicator.remove()
      }
    }, 3000)
  }

  // Méthodes utilitaires pour les totaux
  getTotalGeneral() {
    return Object.values(this.totauxParCategorie).reduce((sum, val) => sum + val, 0)
  }

  getTotalByCategory(categorie) {
    return this.totauxParCategorie[categorie] || 0
  }

  // Méthode pour exporter les résultats
  exportResults() {
    const summary = {
      entreprise: {
        taille: this.hasTailleEntrepriseTarget ? this.tailleEntrepriseTarget.value : null,
        age: this.hasAgeEntrepriseTarget ? this.ageEntrepriseTarget.value : null
      },
      totaux: this.totauxParCategorie,
      total_general: this.getTotalGeneral(),
      date: new Date().toISOString()
    }

    console.log("📋 Export des résultats:", summary)
    return summary
  }

  // Nouvelle méthode pour déclencher l'événement de mise à jour du composant d'économie
  dispatchSavingsUpdateEvent(data) {
    const event = new CustomEvent('savings:update', {
      detail: {
        total_amount: data.total_amount,
        savings_data: data.savings_data
      },
      bubbles: true
    });
    
    document.dispatchEvent(event);
    console.log("💰 Événement savings:update déclenché (Entreprise Bruxelles)", data.savings_data);
  }
}
