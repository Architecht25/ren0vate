import { Controller } from "@hotwired/stimulus"

// Contrôleur dédié aux simulations Wallonie post-login
// Séparé du contrôleur home page pour éviter les conflits
export default class extends Controller {
  static targets = [
    "grandTotal",
    "sectionTitle",
    "currentCategory",
    "selectedPrimesSummary"
  ]

  static values = {
    simulationId: Number
  }

  connect() {

    this.primesData = []
    this.backendCalculatedTotal = 0  // Stocker le total calculé par le backend
    this.currentCategory = this.getCurrentCategory()
    this.setupAutoSaveListeners()

    // Charger les données des primes
    this.loadPrimesData()

    // Restaurer les données sauvegardées
    this.restoreSavedData()

    // Déclencher le premier calcul
    setTimeout(() => {
      this.updateTotalGlobal()
    }, 500)
  }

  setupAutoSaveListeners() {
    // Écouter tous les changements d'inputs dans les cartes Wallonie
    this.element.addEventListener('input', (e) => {
      if (e.target.matches('input, select')) {
        this.debouncedAutoSave();
      }
    });

    this.element.addEventListener('change', (e) => {
      if (e.target.matches('input, select')) {
        this.debouncedAutoSave();
      }
    });

    // Écouter les événements des contrôleurs enfants
    this.element.addEventListener('wallonie:card-changed', (e) => {
      this.debouncedAutoSave();
    });
  }

  getCurrentCategory() {
    let category = localStorage.getItem('selectedWallonieCategory') || 'wallonie_r4'
    // Migrer les anciens formats vers wallonie_r{n}
    if (!category.startsWith('wallonie_r')) {
      const numMatch = category.match(/(\d+)$/)
      category = numMatch ? 'wallonie_r' + numMatch[1] : 'wallonie_r4'
      localStorage.setItem('selectedWallonieCategory', category)
    }
    return category
  }

  get simulationId() {
    return this.simulationIdValue ||
           parseInt(window.location.pathname.match(/\/simulations\/(\d+)/)?.[1]) ||
           null
  }

  async loadPrimesData() {
    try {
      const response = await fetch('/assets/data/primes_wallonie.json')
      if (response.ok) {
        this.primesData = await response.json()
        this.recalculateAllCards()
      }
    } catch (error) {
    }
  }

  recalculateAllCards() {
    const cards = this.element.querySelectorAll('[data-controller~="wallonie-simulation-card"]')
    cards.forEach(card => {
      const controller = this.application.getControllerForElementAndIdentifier(card, 'wallonie-simulation-card')
      if (controller) {
        controller.calculate()
      }
    })
    this.updateTotalGlobal()
  }

  getPrimesData() {
    return this.primesData || {}
  }

  updateTotalGlobal() {
    // Toujours calculer depuis les totaux DOM des cartes (valeur fraîche, jamais depuis un cache)
    let total = 0;

    const cartesSlugs = [
      'wallonie_realisation_audit_logement',
      'wallonie_toiture_global',
      'wallonie_murs_global',
      'wallonie_sols_global',
      'wallonie_ventilation_global',
      'wallonie_chaudiere_global',
      'wallonie_amelioration_chauffage_global',
      'wallonie_eau_chaude_sanitaire_global',
      'wallonie_menuiseries_vitrages',
      'wallonie_installation_electrique',
      'wallonie_installation_gaz'
    ]

    cartesSlugs.forEach(slug => {
      const carteElement = document.querySelector(`[data-wallonie-simulation-card-slug-value="${slug}"]`)
      if (carteElement) {
        const totalElement = carteElement.querySelector('[data-wallonie-simulation-card-target="total"]')
        if (totalElement) {
          const montantText = totalElement.textContent.replace('€', '').replace(/\s/g, '').replace(/\./g, '').replace(',', '.')
          const montant = parseFloat(montantText) || 0
          total += montant
        }
      }
    })


    // Mettre à jour l'affichage du total
    if (this.hasGrandTotalTarget) {
      this.grandTotalTarget.textContent = `${total.toLocaleString('fr-FR', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      })} €`

      // Animation visuelle
      this.grandTotalTarget.classList.add('updated')
      setTimeout(() => {
        this.grandTotalTarget.classList.remove('updated')
      }, 300)
    } else {
    }

    // Émettre un événement pour notifier le total global
    document.dispatchEvent(new CustomEvent('wallonie:total:calculated', {
      detail: { total: total, category: this.currentCategory }
    }))

    // Mettre à jour le résumé des primes sélectionnées
    this.updateSelectedPrimesSummary()
  }

  // Méthode appelée par les cartes enfants pour notifier un changement
  cardUpdated() {
    this.updateTotalGlobal()
  }

  // Méthode pour changer de catégorie (appelée depuis l'interface d'éligibilité)
  changeCategory(newCategory) {
    this.currentCategory = newCategory
    localStorage.setItem('selectedWallonieCategory', newCategory)
    // Mettre à jour aussi la catégorie estimée pour cohérence (extraire le numéro)
    const categoryNumber = newCategory.replace('wallonie_r', '')
    localStorage.setItem('wallonieCategorieEstimee', categoryNumber)
    this.updateSectionTitle()


    // Déclencher le recalcul de toutes les cartes Wallonie
    const wallonieCards = this.element.querySelectorAll('[data-controller*="wallonie-simulation-card"]')
    wallonieCards.forEach(cardElement => {
      // Émettre un événement pour que chaque carte se mette à jour
      cardElement.dispatchEvent(new CustomEvent('wallonie:category:changed', {
        detail: { categorie: newCategory }
      }))
    })

    // Recalculer le total après que toutes les cartes se soient mises à jour
    setTimeout(() => {
      this.updateTotalGlobal()
    }, 100)

    // Mettre à jour l'affichage de la catégorie
    this.updateCategoryDisplay(newCategory)
  }

  updateSectionTitle() {
    if (!this.hasSectionTitleTarget) return

    const categoryNames = {
      'wallonie_r1': 'Revenus R1 (très modestes)',
      'wallonie_r2': 'Revenus R2 (modestes)',
      'wallonie_r3': 'Revenus R3 (moyens)',
      'wallonie_r4': 'Revenus R4 (moyens-supérieurs)',
      'wallonie_r5': 'Revenus R5 (élevés)'
    }

    const categoryName = categoryNames[this.currentCategory] || 'Catégorie non définie'
    this.sectionTitleTarget.textContent = `Primes Wallonie • ${categoryName}`
  }

  updateSelectedPrimesSummary() {
    if (!this.hasSelectedPrimesSummaryTarget) return

    const selectedPrimes = []

    // Parcourir toutes les cartes pour trouver les primes sélectionnées (utiliser les bons slugs)
    const cartesSlugs = [
      'wallonie_realisation_audit_logement',
      'wallonie_toiture_global',
      'wallonie_murs_global',
      'wallonie_sols_global',
      'wallonie_ventilation_global',
      'wallonie_chaudiere_global',
      'wallonie_amelioration_chauffage_global',
      'wallonie_eau_chaude_sanitaire_global',
      'wallonie_menuiseries_vitrages',
      'wallonie_installation_electrique',
      'wallonie_installation_gaz'
    ]

    cartesSlugs.forEach(slug => {
      const carteElement = document.querySelector(`[data-wallonie-simulation-card-slug-value="${slug}"]`)
      if (carteElement) {
        const totalElement = carteElement.querySelector('[data-wallonie-simulation-card-target="total"]')
        if (totalElement) {
          const montantText = totalElement.textContent.replace(/[€\s\.]/g, '').replace(',', '.')
          const montant = parseFloat(montantText) || 0

          if (montant > 0) {
            // Trouver le titre de la carte (bannière latérale)
            const titleElement = carteElement.querySelector('.drop-shadow.fw-bold, h6, h5, .card-title')
            const title = titleElement ? titleElement.textContent.trim() : slug

            selectedPrimes.push({
              title: title.replace(/Prime\s*/i, '').trim(),
              amount: montant
            })
          }
        }
      }
    })

    // Générer le HTML du résumé
    let summaryHTML = ''
    if (selectedPrimes.length > 0) {
      summaryHTML = selectedPrimes.map(prime =>
        `<div class="d-flex justify-content-between align-items-center py-1 border-bottom">
          <span class="small">${prime.title}</span>
          <span class="badge bg-secondary">${prime.amount.toLocaleString('fr-FR')} €</span>
        </div>`
      ).join('')
    } else {
      summaryHTML = '<p class="text-muted small mb-0">Aucune prime sélectionnée</p>'
    }

    this.selectedPrimesSummaryTarget.innerHTML = summaryHTML
  }

  // AUTO-SAVE POUR SIMULATIONS POST-LOGIN

  // Méthode d'auto-save complète
  autoSave() {
    // Vérifier si la restauration est en cours
    if (window.isRestoringValues) {
      return;
    }

    // Protection supplémentaire contre les blocages
    if (window.restorationStartTime && (Date.now() - window.restorationStartTime) > 10000) {
      window.isRestoringValues = false;
    }

    if (!this.simulationId) return;

    // Collecter toutes les données des inputs
    const userInputs = {};
    const allInputs = this.element.querySelectorAll('input[data-slug], select[data-slug]');

    allInputs.forEach(input => {
      const slug = input.dataset.slug;
      if (slug) {
        let value = null;

        if (input.type === 'checkbox') {
          value = input.checked ? 1 : 0;
        } else if (input.type === 'number') {
          value = parseFloat(input.value) || 0;
        } else if (input.tagName === 'SELECT') {
          value = input.value;
        } else {
          value = input.value;
        }

        if (value !== null && value !== '' && value !== '0') {
          userInputs[slug] = value;
        }
      }
    });

    // Sauvegarder via API
    if (Object.keys(userInputs).length > 0) {

      // Calculer le total côté client pour l'envoyer aussi
      const calculatedTotal = this.calculateCurrentTotal();

      fetch(`/fr/simulations/${this.simulationId}/update_prime_inputs`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          user_inputs: userInputs,
          calculated_total: calculatedTotal
        })
      })
      .then(response => response.json())
      .then(data => {
        if (data.success) {

          // Stocker le total calculé par le backend
          this.backendCalculatedTotal = data.total_amount || 0;

          // Mettre à jour les spans individuels avec les détails du backend
          if (data.updated_cards) {
            this.updateIndividualPrimeDisplays(data.updated_cards);
            // Émettre un événement pour que les cartes enfants se mettent à jour
            this.emitPrimeUpdateEvent(data.updated_cards);
          }

          // Mettre à jour le total général avec le vrai total backend
          this.updateTotalGlobal();

          this.showSaveIndicator('success', data.total_amount);
        } else {
          this.showSaveIndicator('error');
        }
      })
      .catch(error => {
        this.showSaveIndicator('error');
      });
    }
  }

  // Calculer le total actuel depuis le DOM
  calculateCurrentTotal() {
    let total = 0;

    // Utiliser la même logique que updateTotalGlobal (slugs corrigés)
    const cartesSlugs = [
      'wallonie_realisation_audit_logement',
      'wallonie_toiture_global',
      'wallonie_murs_global',
      'wallonie_sols_global',
      'wallonie_ventilation_global',
      'wallonie_chaudiere_global',
      'wallonie_amelioration_chauffage_global',
      'wallonie_eau_chaude_sanitaire_global',
      'wallonie_menuiseries_vitrages',
      'wallonie_installation_electrique',
      'wallonie_installation_gaz'
    ]

    // Calculer le total en parcourant toutes les cartes (utiliser les bons sélecteurs)
    cartesSlugs.forEach(slug => {
      const carteElement = document.querySelector(`[data-wallonie-simulation-card-slug-value="${slug}"]`)
      if (carteElement) {
        const totalElement = carteElement.querySelector('[data-wallonie-simulation-card-target="total"]')
        if (totalElement) {
          const montantText = totalElement.textContent.replace('€', '').replace(/\s/g, '').replace(/\./g, '').replace(',', '.')
          const montant = parseFloat(montantText) || 0
          total += montant
        }
      }
    })

    return total;
  }

  // Sauvegarde débounced pour éviter trop d'appels
  debouncedAutoSave() {
    clearTimeout(this.saveTimeout);
    this.saveTimeout = setTimeout(() => this.autoSave(), 1000);
  }

  // Indicateur visuel de sauvegarde
  showSaveIndicator(status, amount = null) {
    const indicator = document.getElementById('save-indicator') || this.createSaveIndicator();

    const message = status === 'success'
      ? `Simulation sauvegardée ! Total calculé: ${amount}€`
      : 'Erreur sauvegarde simulation'

    indicator.className = `position-fixed top-0 end-0 m-3 alert alert-${status === 'success' ? 'success' : 'danger'} alert-dismissible fade show`;
    indicator.style.zIndex = '9999';
    indicator.innerHTML = `
      <i class="bi bi-${status === 'success' ? 'check-circle' : 'exclamation-triangle'} me-2"></i>
      ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;

    // Masquer automatiquement après 3 secondes
    setTimeout(() => {
      if (indicator.parentNode) {
        indicator.remove();
      }
    }, 3000);
  }

  createSaveIndicator() {
    const indicator = document.createElement('div');
    indicator.id = 'save-indicator';
    document.body.appendChild(indicator);
    return indicator;
  }

  // Méthode pour mettre à jour l'affichage de la catégorie
  updateCategoryDisplay(category) {
    if (!this.hasCurrentCategoryTarget) return

    const categoryNames = {
      'wallonie_r1': 'Revenus R1',
      'wallonie_r2': 'Revenus R2',
      'wallonie_r3': 'Revenus R3',
      'wallonie_r4': 'Revenus R4',
      'wallonie_r5': 'Revenus R5'
    }

    const categoryName = categoryNames[category] || 'Catégorie non définie'
    this.currentCategoryTarget.textContent = `${categoryName} • Estimation selon votre profil de revenus`

  }

  // Méthode appelée par les actions des cartes (compatibilité)
  saveUserInput() {
    this.debouncedSaveUserInputs()
  }

  // Émettre un événement pour que les cartes enfants se mettent à jour
  emitPrimeUpdateEvent(updatedCards) {

    // Préparer un objet plat avec tous les montants par slug
    const primeAmounts = {};

    Object.keys(updatedCards).forEach(key => {
      const value = updatedCards[key];

      // Si c'est un nombre direct (slug de prime), l'ajouter
      if (typeof value === 'number') {
        primeAmounts[key] = value;
      }
      // Si c'est un objet avec des primes (catégorie), traiter les primes
      else if (value && value.primes) {
        value.primes.forEach(prime => {
          primeAmounts[prime.slug] = prime.calculated_amount || 0;
        });
      }
    });

    // Émettre l'événement pour toutes les cartes
    const event = new CustomEvent('wallonie:prime-updated', {
      detail: primeAmounts,
      bubbles: true
    });

    document.dispatchEvent(event);
  }

  // Mettre à jour les spans individuels avec les données du backend
  updateIndividualPrimeDisplays(updatedCards) {

    if (!updatedCards) return

    Object.keys(updatedCards).forEach(categoryKey => {
      const categoryData = updatedCards[categoryKey]

      // Si c'est un nombre direct (slug de prime), mettre à jour directement
      if (typeof categoryData === 'number') {
        const slug = categoryKey
        const calculatedAmount = categoryData

        // Trouver la carte correspondante pour Wallonie
        const cardElement = document.querySelector(`[data-wallonie-simulation-card-slug-value="${slug}"]`)

        if (cardElement) {
          const resultSpan = cardElement.querySelector('[data-wallonie-simulation-card-target="total"]')

          if (resultSpan) {
            const formattedAmount = calculatedAmount.toLocaleString('fr-FR')
            resultSpan.textContent = `${formattedAmount} €`
          } else {
          }
        } else {
        }
        return;
      }

      // Si c'est un objet avec des primes (catégorie), traiter les primes
      if (!categoryData.primes) {
        return;
      }


      categoryData.primes.forEach(prime => {
        const slug = prime.slug
        const calculatedAmount = prime.calculated_amount || 0

        // Trouver la carte correspondante pour Wallonie (utiliser le bon sélecteur)
        const cardElement = document.querySelector(`[data-wallonie-simulation-card-slug-value="${slug}"]`)

        if (cardElement) {
          const resultSpan = cardElement.querySelector('[data-wallonie-simulation-card-target="total"]')

          if (resultSpan) {
            const formattedAmount = calculatedAmount.toLocaleString('fr-FR')
            resultSpan.textContent = `${formattedAmount} €`
          } else {
          }
        } else {
        }
      })
    })
  }

  // RESTAURATION DES DONNÉES SAUVEGARDÉES
  async restoreSavedData() {

    if (!this.simulationIdValue) {
      return
    }

    // Marquer le début de la restauration pour éviter l'auto-save pendant
    window.isRestoringValues = true
    window.restorationStartTime = Date.now()

    let hasUpdatedCards = false
    let hasRestoredInputs = false

    try {
      const response = await fetch(`/fr/simulations/${this.simulationIdValue}/restore_prime_inputs`, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })


      if (response.ok) {
        const result = await response.json()

        if (result.success && result.user_inputs) {

          // Restaurer les données de primes Wallonie
          const inputKeys = Object.keys(result.user_inputs)

          if (inputKeys.length > 0) {
            hasRestoredInputs = true
          }

          inputKeys.forEach(slug => {
            this.restorePrimeInput(slug, result.user_inputs[slug])
          })

          // Restaurer le total si disponible
          if (result.total_amount) {
            this.backendCalculatedTotal = result.total_amount
          }

          // Restaurer les cartes mises à jour si disponibles
          if (result.updated_cards) {
            hasUpdatedCards = true
            this.updateIndividualPrimeDisplays(result.updated_cards)
            this.emitPrimeUpdateEvent(result.updated_cards)
          }

          // Recalculer après restauration
          setTimeout(() => {
            this.updateTotalGlobal()
          }, 500)
        }
      } else {
      }
    } catch (error) {
    } finally {
      // Libérer le verrou de restauration après un délai
      // Si le serveur n'a pas fourni les montants calculés, forcer un recalcul via autoSave
      setTimeout(() => {
        window.isRestoringValues = false
        if (hasRestoredInputs && !hasUpdatedCards) {
          this.autoSave()
        }
      }, 1000)
    }
  }

  // Restaurer une donnée de prime Wallonie
  restorePrimeInput(slug, value) {

    // Chercher directement l'input par son data-slug (peu importe la carte parente)
    const input = this.element.querySelector(`input[data-slug="${slug}"], select[data-slug="${slug}"]`)

    if (input) {
      if (input.type === 'checkbox') {
        input.checked = (value == 1 || value === true)
      } else if (input.type === 'number' || input.type === 'text') {
        input.value = value
      } else if (input.tagName === 'SELECT') {
        input.value = value
      }


      // Déclencher les événements pour mettre à jour l'affichage et recalculer
      input.dispatchEvent(new Event('input', { bubbles: true }))
      input.dispatchEvent(new Event('change', { bubbles: true }))
    } else {
      // Si pas trouvé directement, chercher dans la carte correspondante (fallback)
      const cardElement = this.element.querySelector(`[data-wallonie-simulation-card-slug-value="${slug}"]`)
      if (cardElement) {
        const inputs = cardElement.querySelectorAll('input[data-slug], select[data-slug]')

        inputs.forEach(inp => {
          if (inp.dataset.slug === slug) {
            if (inp.type === 'checkbox') {
              inp.checked = (value == 1 || value === true)
            } else {
              inp.value = value
            }
            inp.dispatchEvent(new Event('input', { bubbles: true }))
            inp.dispatchEvent(new Event('change', { bubbles: true }))
          }
        })
      } else {
      }
    }
  }
}
