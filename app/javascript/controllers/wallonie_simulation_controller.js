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
    console.log("🎯 Wallonie Simulation controller connected")
    console.log("📊 Simulation ID:", this.simulationIdValue)

    this.primesData = []
    this.currentCategory = this.getCurrentCategory()
    this.setupAutoSaveListeners()

    // Charger les données des primes
    this.loadPrimesData()

    // Déclencher le premier calcul
    setTimeout(() => {
      this.updateTotalGlobal()
      this.debouncedAutoSave() // Déclencher l'auto-save
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
  }

  getCurrentCategory() {
    // Récupérer la catégorie depuis localStorage ou par défaut
    return localStorage.getItem('selectedWallonieCategory') || 'wallonie_cat2'
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
        console.log("✅ Données primes Wallonie chargées:", Object.keys(this.primesData).length, "primes")
        console.log("🎯 Catégorie Wallonie actuelle:", this.currentCategory)
      } else {
        console.error("❌ Erreur chargement primes Wallonie:", response.status)
      }
    } catch (error) {
      console.error("❌ Erreur chargement primes Wallonie:", error)
    }
  }

  getPrimesData() {
    return this.primesData || {}
  }

  updateTotalGlobal() {
    let total = 0
    console.log("🔄 Calcul du total global Wallonie...")

    // Slugs des cartes Wallonie principales
    const cartesSlugs = [
      'wallonie_prime_global_isolation_toiture',
      'wallonie_prime_global_isolation_murs',
      'wallonie_prime_global_isolation_sols',
      'wallonie_prime_global_menuiseries',
      'wallonie_prime_global_ventilation',
      'wallonie_prime_global_chauffage',
      'wallonie_prime_global_eau_chaude',
      'wallonie_prime_global_electricite',
      'wallonie_prime_global_energies_renouvelables'
    ]

    // Calculer le total en parcourant toutes les cartes
    cartesSlugs.forEach(slug => {
      const carteElement = document.querySelector(`[data-wallonie-prime-card-slug-value="${slug}"]`)
      if (carteElement) {
        const totalElement = carteElement.querySelector('[data-wallonie-prime-card-target="total"]')
        if (totalElement) {
          const montantText = totalElement.textContent.replace('€', '').replace(/\s/g, '').replace(/\./g, '').replace(',', '.')
          const montant = parseFloat(montantText) || 0
          total += montant
          if (montant > 0) {
            console.log(`✅ Carte ${slug}: ${montant}€`)
          }
        } else {
          console.log(`❌ Carte ${slug}: élément total non trouvé`)
        }
      } else {
        console.log(`❌ Carte ${slug}: carte non trouvée`)
      }
    })

    console.log(`🎯 Total global Wallonie calculé: ${total}€`)

    // Mettre à jour l'affichage du total
    if (this.hasGrandTotalTarget) {
      this.grandTotalTarget.textContent = `${total.toLocaleString('fr-FR', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      })} €`
      console.log(`📝 Total affiché: ${this.grandTotalTarget.textContent}`)

      // Animation visuelle
      this.grandTotalTarget.classList.add('updated')
      setTimeout(() => {
        this.grandTotalTarget.classList.remove('updated')
      }, 300)
    } else {
      console.log("❌ Target grandTotal non trouvé!")
    }

    // Émettre un événement pour notifier le total global
    document.dispatchEvent(new CustomEvent('wallonie:total:calculated', {
      detail: { total: total, category: this.currentCategory }
    }))

    // Déclencher l'événement de mise à jour des économies
    this.dispatchSavingsUpdateEvent({
      total_amount: total,
      savings_data: null // sera calculé côté serveur lors du prochain appel AJAX
    });

    // Mettre à jour le résumé des primes sélectionnées
    this.updateSelectedPrimesSummary()
  }

  // Méthode appelée par les cartes enfants pour notifier un changement
  cardUpdated() {
    console.log("🔄 Carte mise à jour - recalcul du total global")
    this.updateTotalGlobal()
  }

  // Méthode pour changer de catégorie (appelée depuis l'interface d'éligibilité)
  changeCategory(newCategory) {
    this.currentCategory = newCategory
    localStorage.setItem('selectedWallonieCategory', newCategory)
    // Mettre à jour aussi la catégorie estimée pour cohérence
    const categoryNumber = newCategory.replace('wallonie_cat', '')
    localStorage.setItem('wallonieCategorieEstimee', categoryNumber)
    this.updateSectionTitle()

    console.log(`🔄 Changement de catégorie vers: ${newCategory}`)

    // Déclencher le recalcul de toutes les cartes Wallonie
    const wallonieCards = this.element.querySelectorAll('[data-controller*="wallonie-prime-card"]')
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
      'wallonie_cat1': 'Catégorie I (revenus très modestes)',
      'wallonie_cat2': 'Catégorie II (revenus modestes)',
      'wallonie_cat3': 'Catégorie III (revenus moyens-élevés)'
    }

    const categoryName = categoryNames[this.currentCategory] || 'Catégorie non définie'
    this.sectionTitleTarget.textContent = `Primes Wallonie • ${categoryName}`
  }

  updateSelectedPrimesSummary() {
    if (!this.hasSelectedPrimesSummaryTarget) return

    const selectedPrimes = []

    // Parcourir toutes les cartes pour trouver les primes sélectionnées
    const cartesSlugs = [
      'wallonie_prime_global_isolation_toiture',
      'wallonie_prime_global_isolation_murs',
      'wallonie_prime_global_isolation_sols',
      'wallonie_prime_global_menuiseries',
      'wallonie_prime_global_ventilation',
      'wallonie_prime_global_chauffage',
      'wallonie_prime_global_eau_chaude',
      'wallonie_prime_global_electricite',
      'wallonie_prime_global_energies_renouvelables'
    ]

    cartesSlugs.forEach(slug => {
      const carteElement = document.querySelector(`[data-wallonie-prime-card-slug-value="${slug}"]`)
      if (carteElement) {
        const totalElement = carteElement.querySelector('[data-wallonie-prime-card-target="total"]')
        if (totalElement) {
          const montantText = totalElement.textContent.replace(/[€\s\.]/g, '').replace(',', '.')
          const montant = parseFloat(montantText) || 0

          if (montant > 0) {
            // Trouver le titre de la carte
            const titleElement = carteElement.querySelector('h6, h5, .card-title')
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
      console.log('🔄 Sauvegarde Wallonie ignorée: restauration en cours');
      return;
    }

    // Protection supplémentaire contre les blocages
    if (window.restorationStartTime && (Date.now() - window.restorationStartTime) > 10000) {
      console.log('⚠️ Restauration Wallonie bloquée depuis > 10s, forçage de la réinitialisation');
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
      console.log('💾 Sauvegarde Wallonie des données:', Object.keys(userInputs).length, 'saisies');

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
          console.log("✅ Auto-save Wallonie réussi:", data.total_amount, "€");
          
          // Déclencher l'événement pour mettre à jour le composant d'économie
          this.dispatchSavingsUpdateEvent(data);
          
          this.showSaveIndicator('success', data.total_amount);
        } else {
          console.error("❌ Erreur auto-save Wallonie:", data.error);
          this.showSaveIndicator('error');
        }
      })
      .catch(error => {
        console.error("❌ Erreur auto-save Wallonie:", error);
        this.showSaveIndicator('error');
      });
    }
  }

  // Calculer le total actuel depuis le DOM
  calculateCurrentTotal() {
    let total = 0;

    // Utiliser la même logique que updateTotalGlobal
    const cartesSlugs = [
      'wallonie_prime_global_isolation_toiture',
      'wallonie_prime_global_isolation_murs',
      'wallonie_prime_global_isolation_sols',
      'wallonie_prime_global_menuiseries',
      'wallonie_prime_global_ventilation',
      'wallonie_prime_global_chauffage',
      'wallonie_prime_global_eau_chaude',
      'wallonie_prime_global_electricite',
      'wallonie_prime_global_energies_renouvelables'
    ]

    // Calculer le total en parcourant toutes les cartes
    cartesSlugs.forEach(slug => {
      const carteElement = document.querySelector(`[data-wallonie-prime-card-slug-value="${slug}"]`)
      if (carteElement) {
        const totalElement = carteElement.querySelector('[data-wallonie-prime-card-target="total"]')
        if (totalElement) {
          const montantText = totalElement.textContent.replace('€', '').replace(/\s/g, '').replace(/\./g, '').replace(',', '.')
          const montant = parseFloat(montantText) || 0
          total += montant
        }
      }
    })

    console.log(`📊 Total calculé côté client: ${total} €`)
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
      'wallonie_cat1': 'Catégorie I',
      'wallonie_cat2': 'Catégorie II',
      'wallonie_cat3': 'Catégorie III'
    }

    const categoryName = categoryNames[category] || 'Catégorie non définie'
    this.currentCategoryTarget.textContent = `${categoryName} • Estimation selon votre profil de revenus`

    console.log(`📋 Catégorie affichée: ${categoryName}`)
  }

  // Méthode appelée par les actions des cartes (compatibilité)
  saveUserInput() {
    this.debouncedSaveUserInputs()
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
    console.log("💰 Événement savings:update déclenché (Wallonie)", data.savings_data);
  }
}
